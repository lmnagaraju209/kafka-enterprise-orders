###############################################
# LOCALS
###############################################

locals {
  private_subnets   = var.existing_private_subnet_ids
  public_subnets    = var.existing_public_subnet_ids

  ecs_tasks_sg      = var.existing_ecs_tasks_sg_id
  alb_sg            = var.existing_alb_sg_id
  rds_sg            = var.existing_rds_sg_id

  alb_arn           = var.existing_alb_arn
  alb_listener_arn  = var.existing_alb_listener_arn
}
