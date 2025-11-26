#############################################
# CREATE NEW ALB (Use existing VPC & SG)
#############################################

resource "aws_lb" "webapp_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_alb_sg_id]
  subnets            = var.existing_public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

#############################################
# Target Group
#############################################

resource "aws_lb_target_group" "webapp_tg" {
  name     = "${var.project_name}-tg"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = var.existing_vpc_id

  health_check {
    enabled             = true
    interval            = 20
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

#############################################
# ALB Listener
#############################################

resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }
}
