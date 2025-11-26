########################################
# General
########################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "kafka-enterprise-orders"
}

########################################
# Container Images (from CI/CD)
########################################

variable "container_image_producer" {
  description = "Docker image for Producer"
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

variable "web_backend_image" {
  description = "Docker image for Web Backend (FastAPI)"
  type        = string
}

variable "web_frontend_image" {
  description = "Docker image for Web Frontend (React)"
  type        = string
}

########################################
# Confluent Cloud (passed from CI/CD)
########################################

variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud bootstrap servers"
  type        = string
}

variable "confluent_api_key" {
  description = "Confluent Cloud API key"
  type        = string
  sensitive   = true
}

variable "confluent_api_secret" {
  description = "Confluent Cloud API secret"
  type        = string
  sensitive   = true
}

########################################
# Kafka Topics
########################################

variable "orders_topic" {
  description = "Orders topic name"
  type        = string
  default     = "orders"
}

variable "fraud_alerts_topic" {
  description = "Fraud alerts topic"
  type        = string
  default     = "fraud-alerts"
}

variable "payments_topic" {
  description = "Payments topic"
  type        = string
  default     = "payments"
}

variable "order_analytics_topic" {
  description = "Order analytics topic"
  type        = string
  default     = "order-analytics"
}

########################################
# Couchbase (backend needs this)
########################################

variable "couchbase_host" {
  description = "Hostname for Couchbase"
  type        = string
  default     = "couchbase"
}

variable "couchbase_bucket" {
  description = "Bucket for analytics data"
  type        = string
  default     = "order_analytics"
}

variable "couchbase_username" {
  description = "Couchbase username"
  type        = string
  default     = "Administrator"
}

variable "couchbase_password" {
  description = "Couchbase password"
  type        = string
  default     = "password"
  sensitive   = true
}

########################################
# RDS Credentials
########################################

variable "rds_username" {
  description = "RDS/Postgres username"
  type        = string
  default     = "orders_user"
}

variable "rds_password" {
  description = "RDS/Postgres password"
  type        = string
  sensitive   = true
}
########################################
# EXISTING INFRA (REUSE INSTEAD OF RECREATE)
########################################

variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID where all Kafka ECS and RDS live"
}

variable "existing_private_subnet_ids" {
  type        = list(string)
  description = "Existing private subnets for ECS and RDS"
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  description = "Existing public subnets for ALB"
}

variable "existing_rds_sg_id" {
  type        = string
  description = "Existing RDS security group ID"
}

variable "existing_alb_sg_id" {
  type        = string
  description = "Existing ALB security group ID"
}

variable "existing_ecs_tasks_sg_id" {
  type        = string
  description = "Existing ECS tasks security group ID"
}

