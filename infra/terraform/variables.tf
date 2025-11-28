# ----------------------
# General Settings
# ----------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Project prefix for naming resources"
  type        = string
}

# ----------------------
# Kafka Microservices Images
# ----------------------
variable "container_image_producer" {
  description = "Docker image for Order Producer"
  type        = string
}

variable "container_image_fraud" {
  description = "Docker image for Fraud Service"
  type        = string
}

variable "container_image_payment" {
  description = "Docker image for Payment Service"
  type        = string
}

variable "container_image_analytics" {
  description = "Docker image for Analytics Service"
  type        = string
}

# ----------------------
# Web App Images (Frontend + Backend)
# ----------------------
variable "container_image_backend" {
  description = "Docker image for Web Backend Service"
  type        = string
}

variable "container_image_frontend" {
  description = "Docker image for Web Frontend (React)"
  type        = string
}

# ----------------------
# Confluent Cloud Credentials
# ----------------------
variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud Bootstrap Servers"
  type        = string
}

variable "confluent_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
}

variable "confluent_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

# ----------------------
# RDS Password
# ----------------------
variable "rds_password" {
  description = "Password for RDS"
  type        = string
  sensitive   = true
}

# ----------------------
# Existing Network Resources
# ----------------------
variable "existing_vpc_id" {
  type = string
}

variable "existing_public_subnet_ids" {
  type = list(string)
}

variable "existing_private_subnet_ids" {
  type = list(string)
}

variable "existing_alb_sg_id" {
  type = string
}

variable "existing_ecs_tasks_sg_id" {
  type = string
}

variable "existing_rds_sg_id" {
  type = string
}

