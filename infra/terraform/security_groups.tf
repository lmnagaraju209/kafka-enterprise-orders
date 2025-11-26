##############################################
# USE EXISTING SECURITY GROUPS (NO CREATION)
##############################################

# ALB SG
data "aws_security_group" "alb_sg" {
  id = var.existing_alb_sg_id
}

# ECS TASKS SG
data "aws_security_group" "ecs_tasks" {
  id = var.existing_ecs_tasks_sg_id
}

# RDS SG
data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id
}
