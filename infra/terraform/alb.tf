###############################
# USE EXISTING ALB
###############################

variable "existing_alb_arn" {
  type        = string
  description = "ARN of existing ALB"
}

variable "existing_alb_sg_id" {
  type        = string
  description = "Security Group of existing ALB"
}

variable "existing_alb_listener_arn" {
  type        = string
  description = "Existing ALB listener ARN"
}

###############################
# DATA LOOKUPS ONLY
###############################

# Lookup existing ALB
data "aws_lb" "webapp_alb" {
  arn = var.existing_alb_arn
}

# Lookup existing ALB listener
data "aws_lb_listener" "webapp_listener" {
  arn = var.existing_alb_listener_arn
}

# Use existing ALB SG
data "aws_security_group" "alb" {
  id = var.existing_alb_sg_id
}

###############################
# TARGET GROUP ONLY (Terraform-managed)
###############################

resource "aws_lb_target_group" "webapp_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
}

###############################
# LISTENER RULE (Terraform-managed)
###############################

resource "aws_lb_listener_rule" "webapp_forward" {
  listener_arn = data.aws_lb_listener.webapp_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
