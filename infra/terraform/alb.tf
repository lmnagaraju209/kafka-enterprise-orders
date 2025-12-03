###############################################
# APPLICATION LOAD BALANCER
###############################################
resource "aws_lb" "ecs_alb" {
  name               = "${local.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
}

###############################################
# TARGET GROUP (short name, 32 chars limit)
###############################################
resource "aws_lb_target_group" "producer_tg" {
  name        = "keo-prod-tg"       # <= FIXED
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-499"
    interval            = 10
    timeout             = 5
    unhealthy_threshold = 3
    healthy_threshold   = 2
  }
}

###############################################
# LISTENER
###############################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer_tg.arn
  }
}

