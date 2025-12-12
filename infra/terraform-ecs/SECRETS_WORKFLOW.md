# Secrets Management Workflow

## One-Time Setup (Only Needed Once)

If secrets already exist in AWS but aren't in Terraform state, import them **once**:

```powershell
cd D:\AJ\kafka-enterprise-orders\infra\terraform-ecs

# Import secrets (use your secrets.tfvars or provide values)
terraform import -var-file=values.auto.tfvars -var-file=secrets.tfvars \
  aws_secretsmanager_secret.ghcr kafka-enterprise-orders-ghcr-credentials

terraform import -var-file=values.auto.tfvars -var-file=secrets.tfvars \
  aws_secretsmanager_secret.confluent kafka-enterprise-orders-confluent-credentials

terraform import -var-file=values.auto.tfvars -var-file=secrets.tfvars \
  aws_secretsmanager_secret.couchbase kafka-enterprise-orders-couchbase-credentials
```

**After this one-time import, you're done!** Terraform will manage the secrets going forward.

## Normal Workflow (After Import)

### Destroy and Recreate

```powershell
# Destroy everything (secrets deleted immediately due to recovery_window_in_days = 0)
terraform destroy

# Recreate everything (secrets created immediately, no waiting)
terraform apply
```

**No import needed!** Terraform knows about the secrets from state, so destroy/recreate works smoothly.

### Update Secret Values

```powershell
# Just update your tfvars file and apply
terraform apply
```

Terraform will update the secret versions (the actual values), not recreate the secrets.

## How It Works

1. **`recovery_window_in_days = 0`**: Secrets are deleted immediately when destroyed (no 7-30 day wait)
2. **Terraform State**: After import, Terraform tracks the secrets in state
3. **Destroy/Recreate**: Works smoothly because:
   - Destroy: Secrets deleted immediately
   - Recreate: New secrets created immediately with same name
   - No conflicts because old secrets are gone

## When Do You Need to Import Again?

**Only if:**
- You lose Terraform state (rare)
- Secrets are created outside Terraform (manually or by another tool)
- You're setting up a new environment from scratch

**You DON'T need to import:**
- After normal `terraform destroy` and `terraform apply`
- When updating secret values
- When adding new secrets

## Summary

- **One-time import**: Get existing secrets into Terraform state
- **After that**: Terraform manages everything automatically
- **Destroy/recreate**: Works smoothly, no manual steps needed
- **`recovery_window_in_days = 0`**: Ensures immediate deletion/recreation

The import is a **one-time setup step**, not something you do every time!

