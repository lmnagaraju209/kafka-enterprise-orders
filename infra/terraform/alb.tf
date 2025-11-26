############################################
# ALB (uses existing VPC + SG)
############################################

resource "aws_lb" "web" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = local.public_subnets
}

resource "aws_lb_target_group" "webapp_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }
}
