##############################################
# Locals for Subnets (Used by ECS, RDS, ALB)
##############################################

locals {
  # Reuse existing subnets from variables
  public_subnets  = var.existing_public_subnet_ids
  private_subnets = var.existing_private_subnet_ids
}
