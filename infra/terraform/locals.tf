locals {
  public_subnets  = [aws_subnet.public[0].id]
  private_subnets = [aws_subnet.private[0].id]
}

