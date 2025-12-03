###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${local.project_name}-alb-main"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.existing_alb_sg_id
  ]

  subnets = var.existing_public_subnet_ids

  tags = {
    Project = local.project_name
  }
}

###############################################
# TARGET GROUP
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "fe-${local.project_name}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Project = local.project_name
  }
}

###############################################
# LISTENER
###############################################

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

