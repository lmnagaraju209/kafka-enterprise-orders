###############################################
# IMPORT EXISTING ALB ONLY (NO VARIABLES HERE)
###############################################

data "aws_lb" "webapp_alb" {
  arn = var.existing_alb_arn
}

data "aws_security_group" "alb" {
  id = var.existing_alb_sg_id
}

data "aws_lb_listener" "webapp_listener" {
  arn = var.existing_alb_listener_arn
}
