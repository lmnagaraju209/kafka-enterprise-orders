###############################################
# TARGET GROUP – FRONTEND ONLY
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "fe-tg"
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
