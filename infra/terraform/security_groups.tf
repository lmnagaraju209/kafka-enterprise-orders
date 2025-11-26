##############################################
# USE EXISTING SECURITY GROUPS (NO CREATION)
##############################################

# Existing ALB SG
data "aws_security_group" "alb_sg" {
  id = var.existing_alb_sg_id
}

# Existing ECS tasks SG
data "aws_security_group" "ecs_tasks" {
  id = var.existing_ecs_tasks_sg_id
}

# Existing RDS SG
data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id
}
