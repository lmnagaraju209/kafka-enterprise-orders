###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_alb_sg_id]
  subnets            = var.existing_public_subnet_ids
}

###############################################
# LISTENER (HTTP : 80)
###############################################

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service Running"
      status_code  = "200"
    }
  }
}

###############################################
# TARGET GROUPS
###############################################

resource "aws_lb_target_group" "order_producer_tg" {
  name        = "order-producer-tg"
  port        = 8080
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

###############################################
# ATTACH ECS SERVICE TO TARGET GROUP
###############################################

resource "aws_lb_listener_rule" "order_producer_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_producer_tg.arn
  }

  condition {
    path_pattern {
      values = ["/producer/*"]
    }
  }
}
