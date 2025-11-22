############################################
# GENERAL SETTINGS
############################################

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Base name prefix for resource naming"
  type        = string
  default     = "kafka-enterprise-orders"
}

############################################
# DOCKER IMAGE VARIABLES (FROM GITHUB ACTIONS)
############################################

variable "container_image_producer" {
  description = "Docker image for order-producer ECS task"
  type        = string
}

variable "container_image_fraud" {
  description = "Docker image for fraud-service ECS task"
  type        = string
}

variable "container_image_payment" {
  description = "Docker image for payment-service ECS task"
  type        = string
}

variable "container_image_analytics" {
  description = "Docker image for analytics-service ECS task"
  type        = string
}

############################################
# CONFLUENT CLOUD CONFIG
############################################

variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud Bootstrap servers"
  type        = string
}

variable "confluent_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
  sensitive   = true
}

variable "confluent_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

############################################
# RDS CONFIGURATION
############################################

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "orders_user"
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

############################################
# OPTIONAL NETWORKING VARIABLES (if needed)
############################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR for public subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR for public subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ecs_cpu" {
  description = "CPU units for ECS tasks"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Memory for ECS tasks"
  type        = number
  default     = 512
}
