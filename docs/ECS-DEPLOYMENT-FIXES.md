# ECS Fixes

## what broke

### image pulls failing (403)
Tasks couldn't pull from GHCR. Added `repositoryCredentials` to task definitions.

### wrong image names
tfvars had wrong names. Fixed to match what's actually in GHCR:
- kafka-enterprise-orders-producer
- kafka-enterprise-orders-fraud-service
- kafka-enterprise-orders-payment-service
- kafka-enterprise-orders-analytics-service
- kafka-enterprise-orders/web-frontend
- kafka-enterprise-orders/web-backend

### credentials exposed
Moved secrets to AWS Secrets Manager (was plaintext in task defs).

Created:
- ghcr-credentials
- confluent-credentials  
- couchbase-credentials

### kafka connection
kafka-python couldn't detect API version. Added `api_version=(2, 6, 0)` to producers/consumers.

### missing topics
Create in Confluent Cloud: orders, payments, fraud-alerts, order-analytics

---

## commands

```bash
cd infra/terraform-ecs && terraform apply

# redeploy
for svc in producer-svc fraud-svc payment-svc analytics-svc frontend-svc backend-svc; do
  aws ecs update-service --cluster kafka-enterprise-orders-cluster --service kafka-enterprise-orders-$svc --force-new-deployment --region us-east-2
done

# logs
aws logs tail /ecs/kafka-enterprise-orders-producer --since 5m --region us-east-2
```

---

## files changed

### new files
| file | lines | what |
|------|-------|------|
| infra/terraform-ecs/secrets.tf | 36 | secrets manager resources |

### modified files
| file | lines | what |
|------|-------|------|
| infra/terraform-ecs/ecs.tf | 415 | repositoryCredentials, secrets block |
| infra/terraform-ecs/variables.tf | 87 | ghcr variables |
| infra/terraform-ecs/values.auto.tfvars | 34 | image names, removed plaintext secrets |
| infra/terraform-ecs/alb.tf | 67 | cleaned up comments |
| infra/terraform-ecs/backend.tf | 9 | cleaned up |
| infra/terraform-ecs/locals.tf | 9 | cleaned up |
| infra/terraform-ecs/outputs.tf | 15 | cleaned up |
| infra/terraform-ecs/monitoring.tf | 30 | cleaned up |
| producer/producer.py | - | added api_version=(2,6,0) |
| consumers/fraud-service/fraud_consumer.py | - | added api_version |
| consumers/payment-service/payment_consumer.py | - | added api_version |
| consumers/analytics-service/analytics_consumer.py | - | added api_version |
