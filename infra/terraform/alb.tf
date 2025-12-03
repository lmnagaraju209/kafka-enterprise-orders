###############################################
# APPLICATION LOAD BALANCER (ALB)
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_alb_sg_id]
  subnets            = var.existing_public_subnet_ids

  tags = {
    Project = var.project_name
  }
}

###############################################
# ALB TARGET GROUP
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "fe-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    unhealthy_threshold = 3
    healthy_threshold   = 3
    timeout             = 5
  }

  tags = {
    Project = var.project_name
  }
}

###############################################
# ALB LISTENER (THIS WAS MISSING)
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

