# ECS Deployment Fixes

Issues encountered and how they were resolved.

---

## 1. GHCR Image Pull Failed

**Error:**
```
CannotPullContainerError: pull image manifest has been retried 5 times
```

**Cause:** Empty password in GHCR credentials.

**Fix:**
```bash
# Check current secret
aws secretsmanager get-secret-value --secret-id kafka-enterprise-orders-ghcr-credentials

# If empty, restore from previous version
aws secretsmanager list-secret-version-ids --secret-id kafka-enterprise-orders-ghcr-credentials

aws secretsmanager get-secret-value \
  --secret-id kafka-enterprise-orders-ghcr-credentials \
  --version-id <previous-version-id>

# Update with correct value
aws secretsmanager update-secret \
  --secret-id kafka-enterprise-orders-ghcr-credentials \
  --secret-string '{"username":"your-github-user","password":"ghp_xxxx"}'
```

---

## 2. Kafka Connection Timeout

**Error:**
```
KafkaTimeoutError: Failed to update metadata after 60.0 secs
```

**Cause:** Confluent credentials were empty in Secrets Manager.

**Fix:**
```bash
# Check secret
aws secretsmanager get-secret-value --secret-id kafka-enterprise-orders-confluent-credentials

# Update with correct values
aws secretsmanager update-secret \
  --secret-id kafka-enterprise-orders-confluent-credentials \
  --secret-string '{"bootstrap_servers":"pkc-xxx.confluent.cloud:9092","api_key":"YOUR_KEY","api_secret":"YOUR_SECRET"}'

# Force ECS to restart and pick up new secrets
aws ecs update-service --cluster kafka-enterprise-orders-cluster --service kafka-enterprise-orders-producer-svc --force-new-deployment
```

---

## 3. Couchbase Connection Failed

**Error:**
```
CouchbaseException: connection failed (empty host)
```

**Cause:** Couchbase credentials overwritten by Terraform apply.

**Fix:**
```bash
# Update Couchbase secret
aws secretsmanager update-secret \
  --secret-id kafka-enterprise-orders-couchbase-credentials \
  --secret-string '{"host":"cb.xxx.cloud.couchbase.com","bucket":"order_analytics","username":"admin","password":"YOUR_PASSWORD"}'

# Restart analytics service
aws ecs update-service --cluster kafka-enterprise-orders-cluster --service kafka-enterprise-orders-analytics-svc --force-new-deployment
```

---

## 4. Backend timedelta Error

**Error:**
```
InvalidArgumentException: Expected timedelta instead of 5
```

**Cause:** Couchbase SDK requires `timedelta` object, not integer.

**Fix in `web/backend/app.py`:**
```python
# Wrong
timeout_options=ClusterTimeoutOptions(kv_timeout=5)

# Correct
from datetime import timedelta
timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=5))
```

---

## 5. Task Not Starting

**Check logs:**
```bash
# Find task ARN
aws ecs list-tasks --cluster kafka-enterprise-orders-cluster --service-name kafka-enterprise-orders-producer-svc

# Get task details
aws ecs describe-tasks --cluster kafka-enterprise-orders-cluster --tasks <task-arn>

# Check CloudWatch logs
aws logs tail /ecs/kafka-enterprise-orders-producer --follow
```

---

## 6. Force Redeploy All Services

```bash
CLUSTER="kafka-enterprise-orders-cluster"

for svc in producer-svc fraud-svc payment-svc analytics-svc backend-svc frontend-svc; do
  aws ecs update-service --cluster $CLUSTER --service kafka-enterprise-orders-$svc --force-new-deployment
done
```

---

## 7. Check Service Health

```bash
# List all services
aws ecs list-services --cluster kafka-enterprise-orders-cluster

# Describe specific service
aws ecs describe-services --cluster kafka-enterprise-orders-cluster --services kafka-enterprise-orders-backend-svc
```

