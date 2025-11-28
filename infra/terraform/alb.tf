###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${local.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"

  subnets         = local.public_subnets
  security_groups = [local.alb_sg_id]

  tags = {
    Project = local.project_name
  }
}

###############################################
# TARGET GROUP (for future web/frontend service)
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "fe-${local.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"  # ✅ for FARGATE

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Project = local.project_name
  }
}

###############################################
# LISTENER (HTTP :80)
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

