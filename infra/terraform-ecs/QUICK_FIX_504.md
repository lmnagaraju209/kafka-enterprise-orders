# Quick Fix: 504 Gateway Timeout

## Root Cause

**Invalid JSON in Couchbase Secret** - The secret format is wrong, causing ECS tasks to fail to start.

## Immediate Fix

### Step 1: Fix Secret Format

The secret must be valid JSON. Run this command:

```bash
aws secretsmanager put-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --secret-string '{"host":"cb.2s2wqp2fpzi0hanx.cloud.couchbase.com","bucket":"order_analytics","username":"admin","password":"P@ssword@1"}' \
  --region us-east-2
```

**Important**: Use single quotes around the JSON, double quotes inside.

### Step 2: Verify Secret is Valid JSON

```bash
aws secretsmanager get-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --region us-east-2 \
  --query 'SecretString' \
  --output text | python -m json.tool
```

If this fails, the JSON is still invalid.

### Step 3: Restart ECS Service

```bash
aws ecs update-service \
  --cluster kafka-enterprise-orders-cluster \
  --service kafka-enterprise-orders-backend-svc \
  --force-new-deployment \
  --region us-east-2
```

Wait 2-3 minutes for new tasks to start.

### Step 4: Apply ALB Timeout Fix

I've already updated `alb.tf` to increase timeout to 120 seconds. Run:

```bash
cd D:\AJ\kafka-enterprise-orders\infra\terraform-ecs
terraform apply
```

## Why 504 Happens

1. **Secret format error** → Tasks fail to start → Fewer healthy targets → ALB timeout
2. **Couchbase connection slow** → Backend takes > 60 seconds → ALB timeout (60s default)
3. **ALB timeout too short** → Backend responds but ALB gives up

## After Fix

- Secret format fixed → Tasks start successfully
- ALB timeout increased → More time for backend to respond
- Backend should work → 504 errors should stop

## Verify It's Fixed

```bash
# Check tasks are running
aws ecs describe-services \
  --cluster kafka-enterprise-orders-cluster \
  --services kafka-enterprise-orders-backend-svc \
  --region us-east-2 \
  --query 'services[0].{Running:runningCount,Desired:desiredCount}'

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --region us-east-2 \
    --query 'TargetGroups[?TargetGroupName==`kafka-enterprise-orders-api-tg`].TargetGroupArn' \
    --output text) \
  --region us-east-2
```

All targets should be "healthy".

