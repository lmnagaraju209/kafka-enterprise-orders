###############################################
# EXISTING VPC
###############################################
data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

###############################################
# EXISTING SUBNETS
###############################################
data "aws_subnet" "private" {
  for_each = toset(var.existing_private_subnet_ids)
  id       = each.key
}

data "aws_subnet" "public" {
  for_each = toset(var.existing_public_subnet_ids)
  id       = each.key
}

###############################################
# EXISTING SECURITY GROUPS
###############################################
data "aws_security_group" "ecs_tasks" {
  id = var.existing_ecs_tasks_sg_id
}

data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id
}

data "aws_security_group" "alb" {
  id = var.existing_alb_sg_id
}

###############################################
# EXISTING ALB + LISTENER
###############################################
data "aws_lb" "webapp_alb" {
  arn = var.existing_alb_arn
}

data "aws_lb_listener" "webapp_listener" {
  arn = var.existing_alb_listener_arn
}
