##############################################
# USE EXISTING VPC AND SUBNETS (DO NOT CREATE)
##############################################

data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

# PRIVATE SUBNETS (for ECS + RDS)
data "aws_subnet" "private" {
  for_each = toset(var.existing_private_subnet_ids)
  id       = each.value
}

# PUBLIC SUBNETS (for ALB)
data "aws_subnet" "public" {
  for_each = toset(var.existing_public_subnet_ids)
  id       = each.value
}
