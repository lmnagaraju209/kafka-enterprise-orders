###############################################
# LOCALS
###############################################

locals {
  vpc_id = var.existing_vpc_id

  # Use the new Terraform-managed subnets
  public_subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]

  private_subnets = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  ecs_tasks_sg_id = var.existing_ecs_tasks_sg_id
  rds_sg_id       = var.existing_rds_sg_id
  alb_sg_id       = var.existing_alb_sg_id
}
