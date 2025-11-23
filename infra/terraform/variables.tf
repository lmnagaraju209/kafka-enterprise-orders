variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "project_name" {
  type        = string
  description = "Project name used for naming resources"
  default     = "kafka-enterprise-orders"
}

# ---------- Container Images (from CI/CD) -----------

variable "container_image_producer" {
  type        = string
  description = "Docker image for order producer"
}

variable "container_image_fraud" {
  type        = string
  description = "Docker image for fraud service"
}

variable "container_image_payment" {
  type        = string
  description = "Docker image for payment service"
}

variable "container_image_analytics" {
  type        = string
  description = "Docker image for analytics service"
}

# ---------- Confluent Cloud -----------

variable "confluent_bootstrap_servers" {
  type        = string
  description = "Bootstrap servers for Confluent Cloud Kafka"
}

variable "confluent_api_key" {
  type        = string
  description = "Confluent Cloud API Key"
}

variable "confluent_api_secret" {
  type        = string
  description = "Confluent Cloud API Secret"
}

# ---------- Kafka Topics -----------

variable "orders_topic" {
  type        = string
  default     = "orders"
}

variable "fraud_alerts_topic" {
  type        = string
  default     = "fraud-alerts"
}

variable "payments_topic" {
  type        = string
  default     = "payments"
}

variable "order_analytics_topic" {
  type        = string
  default     = "order-analytics"
}

# ---------- Couchbase -----------

variable "couchbase_host" {
  type        = string
  default     = "couchbase"
}

variable "couchbase_bucket" {
  type        = string
  default     = "order_analytics"
}

variable "couchbase_username" {
  type        = string
  default     = "Administrator"
}

variable "couchbase_password" {
  type        = string
  default     = "password"
}

# ---------- Networking (CI/CD passes subnet IDs) ----------

variable "public_subnet_a" {
  type        = string
}

variable "public_subnet_b" {
  type        = string
}

variable "ecs_tasks_sg" {
  type        = string
}

# ---------- RDS Password (from GitHub Secret) -----------

variable "rds_password" {
  type        = string
  sensitive   = true
}

