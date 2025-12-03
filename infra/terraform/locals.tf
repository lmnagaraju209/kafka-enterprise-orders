locals {
  # Project name
  project_name = var.project_name

  # Network – using existing values so no conflicts
  vpc_id          = var.existing_vpc_id
  public_subnets  = var.existing_public_subnet_ids
  private_subnets = var.existing_private_subnet_ids

  alb_sg       = var.existing_alb_sg_id
  ecs_tasks_sg = var.existing_ecs_tasks_sg_id
  rds_sg       = var.existing_rds_sg_id
}

