###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [var.existing_alb_sg_id]
  subnets         = local.public_subnets

  tags = {
    Name = "${var.project_name}-alb"
  }
}

###############################################
# TARGET GROUPS
###############################################

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "payment_tg" {
  name        = "payment-tg"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "analytics_tg" {
  name        = "analytics-tg"
  port        = 8083
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
}

###############################################
# LISTENERS
###############################################

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}
