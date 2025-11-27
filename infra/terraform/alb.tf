###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  load_balancer_type = "application"
  internal           = false

  security_groups = [local.alb_sg]
  subnets         = local.public_subnets
}

###############################################
# TARGET GROUP – FRONTEND ONLY
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  # use a prefix so AWS generates a unique name and avoids conflicts
  name_prefix = "fe-"

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    unhealthy_threshold = 2
    healthy_threshold   = 2
    timeout             = 5
  }
}

###############################################
# LISTENER – HTTP 80
###############################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}
