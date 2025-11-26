###############################################
# IMPORT EXISTING SECURITY GROUPS
###############################################

data "aws_security_group" "ecs_tasks" {
  id = var.existing_ecs_tasks_sg_id
}

data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id
}
