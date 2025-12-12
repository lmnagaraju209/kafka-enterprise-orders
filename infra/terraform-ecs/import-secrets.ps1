# Import existing secrets into Terraform state
# Run this from the terraform-ecs directory

$ErrorActionPreference = "Stop"

Write-Host "Importing secrets into Terraform state..." -ForegroundColor Green

# You'll need to provide these values - they're not stored in the script for security
# You can get them from your secrets.tfvars or provide them interactively
$ghcrPat = Read-Host "Enter GHCR PAT (or press Enter to skip)"
$confluentApiKey = Read-Host "Enter Confluent API Key (or press Enter to skip)"
$confluentApiSecret = Read-Host "Enter Confluent API Secret (or press Enter to skip)"
$couchbaseUsername = Read-Host "Enter Couchbase Username (or press Enter to skip)"
$couchbasePassword = Read-Host "Enter Couchbase Password (or press Enter to skip)"

# Build terraform import command with variables
$varArgs = @()
if ($ghcrPat) { $varArgs += "-var=`"ghcr_pat=$ghcrPat`"" }
if ($confluentApiKey) { $varArgs += "-var=`"confluent_api_key=$confluentApiKey`"" }
if ($confluentApiSecret) { $varArgs += "-var=`"confluent_api_secret=$confluentApiSecret`"" }
if ($couchbaseUsername) { $varArgs += "-var=`"couchbase_username=$couchbaseUsername`"" }
if ($couchbasePassword) { $varArgs += "-var=`"couchbase_password=$couchbasePassword`"" }

$varArgs += "-var-file=values.auto.tfvars"

Write-Host "`nImporting ghcr secret..." -ForegroundColor Yellow
terraform import $varArgs aws_secretsmanager_secret.ghcr "kafka-enterprise-orders-ghcr-credentials"

Write-Host "`nImporting confluent secret..." -ForegroundColor Yellow
terraform import $varArgs aws_secretsmanager_secret.confluent "kafka-enterprise-orders-confluent-credentials"

Write-Host "`nImporting couchbase secret..." -ForegroundColor Yellow
terraform import $varArgs aws_secretsmanager_secret.couchbase "kafka-enterprise-orders-couchbase-credentials"

Write-Host "`nDone! Secrets imported into Terraform state." -ForegroundColor Green
Write-Host "You can now run: terraform apply" -ForegroundColor Green

