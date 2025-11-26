##############################################
# EXISTING VPC + SUBNETS (NO CREATION)
##############################################

data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

data "aws_subnet" "private" {
  for_each = toset(var.existing_private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(var.existing_public_subnet_ids)
  id       = each.value
}
