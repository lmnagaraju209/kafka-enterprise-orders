resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
}

# Target group for the producer service
# Name must be <= 32 characters
resource "aws_lb_target_group" "producer_tg" {
  name        = "${var.project_name}-prod-tg" # e.g. kafka-enterprise-orders-prod-tg (31 chars)
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/actuator/health"
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.producer_tg.arn
        weight = 1
      }
    }
  }
}

