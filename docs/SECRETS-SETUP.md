# Secrets Setup

## Terraform

Terraform creates all secrets automatically. Just run:

```bash
cd infra/terraform-ecs
terraform apply
```

It prompts for:
- `ghcr_pat` - GitHub PAT (github.com/settings/tokens, scope: read:packages)
- `confluent_api_key` - Confluent Cloud API key
- `confluent_api_secret` - Confluent Cloud API secret  
- `couchbase_password` - Couchbase database password

### Alternative: Environment Variables

```bash
export TF_VAR_ghcr_pat="ghp_xxx"
export TF_VAR_confluent_api_key="xxx"
export TF_VAR_confluent_api_secret="xxx"
export TF_VAR_couchbase_password="xxx"
terraform apply
```

### Alternative: tfvars File

```bash
cp secrets.tfvars.example secrets.tfvars
# edit secrets.tfvars
terraform apply -var-file="secrets.tfvars"
```

## Helm (EKS)

```bash
helm upgrade webapp k8s/charts/webapp \
  --set ghcr.password=ghp_xxx \
  --set couchbase.password=xxx
```

## Getting Credentials

| Service | URL | What to get |
|---------|-----|-------------|
| GHCR | github.com/settings/tokens | PAT with `read:packages` |
| Confluent | confluent.cloud | Cluster > API Keys |
| Couchbase | cloud.couchbase.com | Settings > Database Access |

## Couchbase IP Whitelist

Add in Capella: Settings > Allowed IP Addresses
- Testing: `0.0.0.0/0`
- Production: NAT Gateway IPs

## Redeploy After Changes

```bash
# ECS
aws ecs update-service --cluster kafka-enterprise-orders-cluster \
  --service kafka-enterprise-orders-backend-svc --force-new-deployment

# EKS  
kubectl rollout restart deployment web-backend
```
