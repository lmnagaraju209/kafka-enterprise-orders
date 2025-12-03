###############################################
# PROJECT METADATA
###############################################

variable "project_name" {
  description = "Project name used for naming ECS, ALB, TG, and other resources"
  type        = string
  default     = "kafka-enterprise-orders"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-2"
}

###############################################
# CONTAINER IMAGES
###############################################

variable "container_image_producer" {
  description = "Docker image for producer service"
  type        = string
}

variable "container_image_fraud" {
  description = "Docker image for fraud service"
  type        = string
}

variable "container_image_payment" {
  description = "Docker image for payment service"
  type        = string
}

variable "container_image_analytics" {
  description = "Docker image for analytics service"
  type        = string
}

variable "container_image_backend" {
  description = "Docker image for backend service"
  type        = string
}

variable "container_image_frontend" {
  description = "Docker image for frontend service"
  type        = string
}

###############################################
# CONFLUENT CONNECTION VALUES
###############################################

variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud bootstrap servers"
  type        = string
}

variable "confluent_api_key" {
  description = "Confluent API Key"
  type        = string
}

variable "confluent_api_secret" {
  description = "Confluent API Secret"
  type        = string
  sensitive   = true
}

###############################################
# POSTGRES / RDS
###############################################

variable "rds_password" {
  description = "Password for RDS PostgreSQL"
  type        = string
  sensitive   = true
}

###############################################
# EXISTING NETWORK (STATIC)
###############################################

variable "existing_vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "existing_public_subnet_ids" {
  description = "List of existing PUBLIC subnets"
  type        = list(string)
}

variable "existing_private_subnet_ids" {
  description = "List of existing PRIVATE subnets"
  type        = list(string)
}

variable "existing_alb_sg_id" {
  description = "Existing ALB Security Group"
  type        = string
}

variable "existing_ecs_tasks_sg_id" {
  description = "Existing ECS Tasks Security Group"
  type        = string
}

variable "existing_rds_sg_id" {
  description = "Existing RDS Security Group"
  type        = string
}

