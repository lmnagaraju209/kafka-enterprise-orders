# Troubleshooting: Couchbase Authentication & 504 Timeout

## Issues

1. **Couchbase Authentication Error**: `authentication_failure (6)`
2. **504 Gateway Timeout**: Application not responding

## Root Causes

### Couchbase Authentication Failure

**Error**: `AuthenticationException: authentication_failure (6). Possible reasons: incorrect authentication configuration, bucket doesn't exist or bucket may be hibernated.`

**Possible causes**:
1. **Wrong password** in AWS Secrets Manager
2. **Bucket doesn't exist** or is hibernated in Couchbase Capella
3. **Username is wrong** (should be the database user, not admin)
4. **Network connectivity** issue (can't reach Couchbase)

### 504 Gateway Timeout

**Causes**:
1. Backend service is crashing/restarting
2. Health checks failing
3. Tasks not running
4. ALB can't reach backend

## Fix Steps

### 1. Verify Couchbase Secret Values

```bash
# Check what's in the secret
aws secretsmanager get-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --region us-east-2 \
  --query 'SecretString' \
  --output text
```

**Verify**:
- `host`: Should be `cb.2s2wqp2fpzi0hanx.cloud.couchbase.com`
- `bucket`: Should be `order_analytics`
- `username`: Should be the **database user** (not "admin" - that's the cluster admin)
- `password`: Should be the **database user password** (not cluster admin password)

### 2. Check Couchbase Capella

1. Log into Couchbase Capella console
2. Verify the bucket `order_analytics` exists and is **not hibernated**
3. Verify you have a **database user** (not cluster admin) with:
   - Username: (check in Capella)
   - Password: (check in Capella)
   - Permissions: Read/Write on `order_analytics` bucket

### 3. Update Secret if Wrong

If the password/username is wrong:

```bash
# Update the secret
aws secretsmanager put-secret-value \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --secret-string '{"host":"cb.2s2wqp2fpzi0hanx.cloud.couchbase.com","bucket":"order_analytics","username":"YOUR_DB_USER","password":"YOUR_DB_PASSWORD"}' \
  --region us-east-2
```

Then restart the ECS service:

```bash
aws ecs update-service \
  --cluster kafka-enterprise-orders-cluster \
  --service kafka-enterprise-orders-backend-svc \
  --force-new-deployment \
  --region us-east-2
```

### 4. Check Backend Logs

```bash
# Check for Couchbase errors
aws logs tail /ecs/kafka-enterprise-orders-backend \
  --region us-east-2 \
  --since 30m \
  --format short | grep -i "couchbase\|error\|exception"
```

### 5. Check ALB Target Health

```bash
# Check if targets are healthy
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --region us-east-2 \
    --query 'TargetGroups[?TargetGroupName==`kafka-enterprise-orders-api-tg`].TargetGroupArn' \
    --output text) \
  --region us-east-2
```

### 6. Restart Services

If everything looks correct but still failing:

```bash
# Force new deployment (restarts tasks)
aws ecs update-service \
  --cluster kafka-enterprise-orders-cluster \
  --service kafka-enterprise-orders-backend-svc \
  --force-new-deployment \
  --region us-east-2

# Wait 2-3 minutes, then check again
```

## Common Issues

### Issue: Using Cluster Admin Instead of Database User

**Problem**: Using cluster admin credentials instead of database user credentials.

**Fix**: Create a database user in Couchbase Capella with read/write permissions on the bucket, then update the secret.

### Issue: Bucket Hibernated

**Problem**: Couchbase Capella buckets hibernate after inactivity.

**Fix**: Wake up the bucket in Couchbase Capella console.

### Issue: Wrong Connection String

**Problem**: Code might be using wrong protocol.

**Fix**: The code already handles this - it uses `couchbases://` for cloud.couchbase.com (TLS) and `couchbase://` for others.

## Quick Test

Test Couchbase connection from your local machine:

```python
from couchbase.cluster import Cluster, ClusterOptions
from couchbase.auth import PasswordAuthenticator

cluster = Cluster(
    "couchbases://cb.2s2wqp2fpzi0hanx.cloud.couchbase.com",
    ClusterOptions(
        PasswordAuthenticator("YOUR_DB_USER", "YOUR_DB_PASSWORD")
    )
)

bucket = cluster.bucket("order_analytics")
print("Connected!")
```

If this works locally but not in ECS, it's a network/secret issue. If it doesn't work locally, it's a Couchbase configuration issue.

