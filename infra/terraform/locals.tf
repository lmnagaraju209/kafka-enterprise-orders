##############################################
# Locals for Subnets (Used by ECS, RDS, ALB)
##############################################

locals {
  public_subnets  = aws_subnet.public[*].id
  private_subnets = aws_subnet.private[*].id
}

