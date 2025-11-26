locals {
  vpc_id          = var.existing_vpc_id
  private_subnets = var.existing_private_subnet_ids
  public_subnets  = var.existing_public_subnet_ids

  # SECURITY GROUPS WE ARE REUSING
  rds_sg          = var.existing_rds_sg_id
  ecs_tasks_sg    = var.existing_ecs_tasks_sg_id

  # ALB SG IS NEW (created in alb.tf)
  alb_sg          = aws_security_group.alb_sg.id
}
