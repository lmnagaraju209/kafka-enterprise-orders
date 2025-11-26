##############################################
# USE EXISTING VPC — DO NOT CREATE NEW VPC
##############################################

data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

##############################################
# USE EXISTING SUBNETS
##############################################

data "aws_subnet" "private" {
  for_each = toset(var.existing_private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(var.existing_public_subnet_ids)
  id       = each.value
}

##############################################
# INTERNET GATEWAY (EXISTING OR NEW)
##############################################

data "aws_internet_gateway" "igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.existing_vpc_id]
  }
}

##############################################
# PUBLIC ROUTE TABLE (EXISTING)
##############################################

data "aws_route_table" "public_rt" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "association.main"
    values = ["true"]
  }
}
