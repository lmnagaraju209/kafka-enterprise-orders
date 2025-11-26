##############################################
# USE EXISTING ALB (DATA SOURCE)
##############################################

data "aws_lb" "webapp_alb" {
  name = "${var.project_name}-alb"
}

##############################################
# TARGET GROUP (still created by Terraform)
##############################################

resource "aws_lb_target_group" "webapp_tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

##############################################
# LISTENER (uses existing ALB)
##############################################

resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = data.aws_lb.webapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }
}
