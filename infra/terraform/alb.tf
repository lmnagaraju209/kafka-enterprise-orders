###########################################
# APPLICATION LOAD BALANCER
###########################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.alb_sg]
  subnets            = local.public_subnets
}

###########################################
# TARGET GROUP (MUST BE ip)
###########################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "fe-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"   # <<< THIS FIXES YOUR ERROR

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

###########################################
# LISTENER
###########################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

