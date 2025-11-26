###############################################
# Project
###############################################
variable "project_name" {
  type        = string
  default     = "kafka-enterprise-orders"
}

###############################################
# AWS Region
###############################################
variable "aws_region" {
  type        = string
  default     = "us-east-2"
}

###############################################
# EXISTING VPC + SUBNETS + SGs (IMPORT MODE)
###############################################

variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID"
}

variable "existing_private_subnet_ids" {
  type        = list(string)
  description = "Two existing private subnet IDs"
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  description = "Two existing public subnet IDs"
}

variable "existing_rds_sg_id" {
  type        = string
  description = "Existing RDS security group ID"
}

variable "existing_ecs_tasks_sg_id" {
  type        = string
  description = "Existing ECS tasks security group ID"
}

###############################################
# EXISTING ALB (REQUIRED FOR FIXING WAF)
###############################################

variable "existing_alb_arn" {
  type        = string
  description = "ARN of the existing ALB"
}

variable "existing_alb_sg_id" {
  type        = string
  description = "Existing ALB security group ID"
}

variable "existing_alb_listener_arn" {
  type        = string
  description = "Existing ALB listener ARN (port 80 or 443)"
}

###############################################
# ECS Task Images
###############################################

variable "container_image_producer" {
  type = string
}

variable "container_image_fraud" {
  type = string
}

variable "container_image_payment" {
  type = string
}

variable "container_image_analytics" {
  type = string
}

###############################################
# Web Backend + Frontend Images
###############################################

variable "web_backend_image" {
  type = string
}

variable "web_frontend_image" {
  type = string
}

###############################################
# RDS Credentials
###############################################

variable "rds_password" {
  type      = string
  sensitive = true
}

###############################################
# Confluent Cloud
###############################################

variable "confluent_bootstrap_servers" {
  type = string
}

variable "confluent_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_api_secret" {
  type      = string
  sensitive = true
}

###############################################
# ECS Configuration
###############################################

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "ecs_max_count" {
  type    = number
  default = 4
}

###############################################
# Tags
###############################################

variable "default_tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "kafka-enterprise-orders"
  }
}
