# Fix: 504 Gateway Timeout Error

## Root Causes

### 1. Secret Format Error (Primary Issue)

**Error in ECS Events**:
```
unable to retrieve secret from asm: invalid character 'h' looking for beginning of object key string
```

**Problem**: The secret JSON format might be corrupted or invalid.

### 2. Couchbase Connection Timeout

The backend code has a 5-second timeout for Couchbase:
```python
timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=5))
```

If Couchbase connection fails/hangs, it could cause 504s.

### 3. ALB Idle Timeout

Default ALB idle timeout is 60 seconds. If backend takes longer, ALB returns 504.

## Fixes

### Fix 1: Verify and Fix Secret Format

The secret must be valid JSON. Check current format:

```bash
aws secretsmanager get-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --region us-east-2 \
  --query 'SecretString' \
  --output text
```

**Expected format** (valid JSON):
```json
{"host":"cb.2s2wqp2fpzi0hanx.cloud.couchbase.com","bucket":"order_analytics","username":"db_user","password":"db_password"}
```

**If format is wrong**, update it:

```bash
aws secretsmanager put-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --secret-string '{"host":"cb.2s2wqp2fpzi0hanx.cloud.couchbase.com","bucket":"order_analytics","username":"YOUR_DB_USER","password":"YOUR_DB_PASSWORD"}' \
  --region us-east-2
```

**Important**: Use single quotes around the JSON string, and double quotes inside JSON.

### Fix 2: Increase ALB Idle Timeout

Add to `alb.tf`:

```hcl
resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.alb_sg]
  subnets            = local.public_subnets
  
  # Increase idle timeout to 120 seconds (default is 60)
  # This gives backend more time to respond, especially if Couchbase is slow
  idle_timeout = 120
}
```

Then run:
```bash
terraform apply
```

### Fix 3: Add Error Handling in Backend

The backend should handle Couchbase errors gracefully and return quickly. Update `app.py`:

```python
@app.get("/api/analytics")
def get_analytics():
    try:
        conn_str = f"couchbases://{COUCHBASE_HOST}" if "cloud.couchbase.com" in COUCHBASE_HOST else f"couchbase://{COUCHBASE_HOST}"
        
        cluster = Cluster(
            conn_str,
            ClusterOptions(
                PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
                timeout_options=ClusterTimeoutOptions(
                    kv_timeout=timedelta(seconds=3),  # Reduce to 3 seconds
                    query_timeout=timedelta(seconds=3)
                )
            )
        )

        bucket = cluster.bucket(COUCHBASE_BUCKET)
        result = cluster.query(f"SELECT * FROM `{COUCHBASE_BUCKET}` LIMIT 10;")

        return {"status": "ok", "orders": [row for row in result]}

    except Exception as e:
        # Return error quickly instead of hanging
        return {
            "status": "error",
            "message": str(e),
            "orders": []
        }, 200  # Still return 200, but with error in body
```

### Fix 4: Restart ECS Service After Secret Fix

After fixing the secret:

```bash
aws ecs update-service \
  --cluster kafka-enterprise-orders-cluster \
  --service kafka-enterprise-orders-backend-svc \
  --force-new-deployment \
  --region us-east-2
```

## Quick Diagnostic Commands

### Check Secret Format
```bash
aws secretsmanager get-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --region us-east-2 \
  --query 'SecretString' \
  --output text | python -m json.tool
```

If this fails, the JSON is invalid.

### Check ALB Timeout
```bash
aws elbv2 describe-load-balancer-attributes \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
    --region us-east-2 \
    --query 'LoadBalancers[?contains(LoadBalancerName, `kafka-enterprise-orders`)].LoadBalancerArn' \
    --output text) \
  --region us-east-2 \
  --query 'Attributes[?Key==`idle_timeout.timeout_seconds`]'
```

### Check Backend Response Times
```bash
aws logs tail /ecs/kafka-enterprise-orders-backend \
  --region us-east-2 \
  --since 10m \
  --format short | grep "GET /api"
```

Look for slow responses (taking > 60 seconds).

## Summary

**Primary Issue**: Secret format error causing tasks to fail
**Secondary Issue**: Couchbase connection timeout causing slow responses
**Tertiary Issue**: ALB timeout too short

**Fix Order**:
1. Fix secret JSON format (most important)
2. Restart ECS service
3. Increase ALB idle timeout
4. Improve backend error handling

