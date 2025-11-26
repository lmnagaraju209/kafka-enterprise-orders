##############################################
# REUSE EXISTING INFRASTRUCTURE
##############################################

# Reuse existing VPC
data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

# Reuse existing private subnets
data "aws_subnets" "private" {
  ids = var.existing_private_subnet_ids
}

# Reuse existing public subnets
data "aws_subnets" "public" {
  ids = var.existing_public_subnet_ids
}

# Reuse existing RDS SG
data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id
}

# Reuse existing ECS tasks SG
data "aws_security_group" "ecs_tasks" {
  id = var.existing_ecs_tasks_sg_id
}

##############################################
# ALB SG (new)
##############################################

# ALB SG is created new in alb.tf
