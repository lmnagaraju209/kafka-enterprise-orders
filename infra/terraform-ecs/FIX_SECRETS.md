# Fix: Secrets Already Exist Error

## The Problem

Terraform is trying to CREATE secrets, but they already exist in AWS. Terraform state doesn't know about them, so it thinks they need to be created.

## The Solution: Import Secrets into Terraform State

Since the secrets already exist in AWS, we need to import them into Terraform state so Terraform knows they exist.

## Quick Fix

Run these commands from the `terraform-ecs` directory:

```powershell
cd D:\AJ\kafka-enterprise-orders\infra\terraform-ecs

# Import secrets (you'll need to provide the secret values when prompted)
# Or use the import-secrets.ps1 script I created

terraform import -var-file=values.auto.tfvars `
  -var="ghcr_pat=YOUR_GHCR_PAT" `
  -var="confluent_api_key=YOUR_API_KEY" `
  -var="confluent_api_secret=YOUR_API_SECRET" `
  -var="couchbase_username=YOUR_USERNAME" `
  -var="couchbase_password=YOUR_PASSWORD" `
  aws_secretsmanager_secret.ghcr kafka-enterprise-orders-ghcr-credentials

terraform import -var-file=values.auto.tfvars `
  -var="ghcr_pat=YOUR_GHCR_PAT" `
  -var="confluent_api_key=YOUR_API_KEY" `
  -var="confluent_api_secret=YOUR_API_SECRET" `
  -var="couchbase_username=YOUR_USERNAME" `
  -var="couchbase_password=YOUR_PASSWORD" `
  aws_secretsmanager_secret.confluent kafka-enterprise-orders-confluent-credentials

terraform import -var-file=values.auto.tfvars `
  -var="ghcr_pat=YOUR_GHCR_PAT" `
  -var="confluent_api_key=YOUR_API_KEY" `
  -var="confluent_api_secret=YOUR_API_SECRET" `
  -var="couchbase_username=YOUR_USERNAME" `
  -var="couchbase_password=YOUR_PASSWORD" `
  aws_secretsmanager_secret.couchbase kafka-enterprise-orders-couchbase-credentials
```

Replace `YOUR_*` with your actual values, or use the `import-secrets.ps1` script which will prompt you.

## Alternative: Use the Script

I created `import-secrets.ps1` - just run it:

```powershell
.\import-secrets.ps1
```

It will prompt you for the secret values and import all three secrets.

## After Import

Once imported, run:

```powershell
terraform apply
```

Terraform will now know the secrets exist and will only update the secret versions (the actual values), not try to create new secrets.

## Why This Happens

- Secrets exist in AWS (we restored them earlier)
- Terraform state doesn't have them (they were created outside Terraform or state was lost)
- Terraform tries to create them → Error: "already exists"
- Solution: Import them so Terraform knows they exist

