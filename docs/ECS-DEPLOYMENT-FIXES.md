# ECS Deployment Fixes

Notes on what we had to fix to get this running on ECS.

## Image pull failures

Tasks couldn't pull from GHCR - got 403 errors. Had to add `repositoryCredentials` to all the task definitions pointing to the ghcr secret in secrets manager.

## Wrong image names

The image names in tfvars didn't match what was actually in GHCR. Fixed them to use the right naming:
- `kafka-enterprise-orders-producer`
- `kafka-enterprise-orders-fraud-service`
- `kafka-enterprise-orders-payment-service`
- `kafka-enterprise-orders-analytics-service`
- `kafka-enterprise-orders/web-frontend`
- `kafka-enterprise-orders/web-backend`

## Credentials in plaintext

Moved all the sensitive stuff to Secrets Manager instead of having it in the task definition env vars. Created secrets.tf for this.

Secrets created:
- `ghcr-credentials` - for pulling images
- `confluent-credentials` - kafka connection
- `couchbase-credentials` - db connection

## Kafka connection issues

The kafka-python lib couldn't auto-detect the API version with Confluent Cloud. Added `api_version=(2, 6, 0)` to all the producers and consumers.

## Missing topics

Services were timing out because the kafka topics didn't exist. Need to create these in Confluent Cloud:
- orders
- payments  
- fraud-alerts
- order-analytics

---

## Useful commands

```bash
# apply terraform
cd infra/terraform-ecs
terraform apply

# force redeploy all services
for svc in producer-svc fraud-svc payment-svc analytics-svc frontend-svc backend-svc; do
  aws ecs update-service --cluster kafka-enterprise-orders-cluster --service kafka-enterprise-orders-$svc --force-new-deployment --region us-east-2
done

# check logs
aws logs tail /ecs/kafka-enterprise-orders-producer --since 5m --region us-east-2
```
