###############################################
# APPLICATION LOAD BALANCER
###############################################

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-main"
  load_balancer_type = "application"
  security_groups    = [local.alb_sg]            # comes from locals.tf
  subnets            = local.public_subnets      # from values.auto.tfvars

  idle_timeout       = 60

  tags = {
    Name = "${var.project_name}-alb-main"
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################################
# TARGET GROUP
###############################################

resource "aws_lb_target_group" "frontend_tg" {
  name        = "fe-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"                     # REQUIRED for ECS FARGATE

  deregistration_delay = 0

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  # FIX: allow Terraform to replace TG even if attached
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "fe-${var.project_name}"
  }
}

###############################################
# LISTENER (HTTP → TARGET GROUP)
###############################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

