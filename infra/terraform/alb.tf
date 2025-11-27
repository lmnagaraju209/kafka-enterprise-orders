###############################################
# EXISTING TARGET GROUPS (already in AWS)
###############################################

data "aws_lb_target_group" "backend_tg" {
  name = "backend-tg"
}

data "aws_lb_target_group" "frontend_tg" {
  name = "frontend-tg"
}

data "aws_lb_target_group" "payment_tg" {
  name = "payment-tg"
}

data "aws_lb_target_group" "analytics_tg" {
  name = "analytics-tg"
}

###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [local.alb_sg_id]
  subnets         = local.public_subnets

  tags = {
    Name = "${var.project_name}-alb"
  }
}

###############################################
# LISTENER (forward to existing frontend TG by default)
###############################################

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.frontend_tg.arn
  }
}
