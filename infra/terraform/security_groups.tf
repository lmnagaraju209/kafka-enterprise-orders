###############################################
# IMPORT EXISTING SECURITY GROUPS
###############################################

variable "existing_ecs_tasks_sg_id" {
  type        = string
  description = "Existing ECS tasks SG"
}

variable "existing_rds_sg_id" {
  type        = string
  description = "Existing RDS SG"
}

# ECS Tasks SG (existing)
data "aws_security_group" "ecs_tasks" {
  id = var.existing_ecs_tasks_sg_id
}

# RDS SG (existing)
data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id
}

# ALB SG is now in alb.tf ONLY — removed from here
