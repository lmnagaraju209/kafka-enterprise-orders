###############################################
# IMPORT EXISTING ALB ONLY
###############################################

variable "existing_alb_arn" {
  type        = string
  description = "Existing ALB ARN"
}

variable "existing_alb_sg_id" {
  type        = string
  description = "Existing ALB Security Group ID"
}

variable "existing_alb_listener_arn" {
  type        = string
  description = "Existing ALB Listener ARN"
}

# Import the ALB so Terraform can read it
data "aws_lb" "webapp_alb" {
  arn = var.existing_alb_arn
}

# Import the ALB security group
data "aws_security_group" "alb" {
  id = var.existing_alb_sg_id
}

# Import listener
data "aws_lb_listener" "webapp_listener" {
  arn = var.existing_alb_listener_arn
}

