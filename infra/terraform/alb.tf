###############################################
# APPLICATION LOAD BALANCER FOR ECS SERVICES
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_alb_sg_id]
  subnets            = var.existing_public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb-main"
  }
}

###############################################
# TARGET GROUP (IP MODE FOR FARGATE)
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "ip" # IMPORTANT FOR FARGATE

  health_check {
    path                = "/actuator/health"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 3
    healthy_threshold   = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

###############################################
# LISTENER (PORT 80)
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

