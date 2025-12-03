locals {
  project_name = var.project_name

  vpc_id               = var.existing_vpc_id
  public_subnets       = var.existing_public_subnet_ids
  private_subnets      = var.existing_private_subnet_ids

  alb_sg_id            = var.existing_alb_sg_id
  ecs_tasks_sg_id      = var.existing_ecs_tasks_sg_id
  rds_sg_id            = var.existing_rds_sg_id
}

