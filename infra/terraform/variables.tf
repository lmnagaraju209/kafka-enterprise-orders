########################################
# General
########################################

variable "aws_region" {
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  type        = string
  default     = "kafka-enterprise-orders"
}

########################################
# Containers (from CI/CD)
########################################

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

variable "web_backend_image" {
  type = string
}

variable "web_frontend_image" {
  type = string
}

########################################
# Confluent Cloud
########################################

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

########################################
# Kafka Topics
########################################

variable "orders_topic" {
  type    = string
  default = "orders"
}

variable "fraud_alerts_topic" {
  type    = string
  default = "fraud-alerts"
}

variable "payments_topic" {
  type    = string
  default = "payments"
}

variable "order_analytics_topic" {
  type    = string
  default = "order-analytics"
}

########################################
# Couchbase
########################################

variable "couchbase_host" {
  type    = string
  default = "couchbase"
}

variable "couchbase_bucket" {
  type    = string
  default = "order_analytics"
}

variable "couchbase_username" {
  type    = string
  default = "Administrator"
}

variable "couchbase_password" {
  type      = string
  default   = "password"
  sensitive = true
}

########################################
# RDS Credentials
########################################

variable "rds_username" {
  type    = string
  default = "orders_user"
}

variable "rds_password" {
  type      = string
  sensitive = true
}

########################################
# EXISTING VPC + SGs
########################################

variable "existing_vpc_id" {
  type = string
}

variable "existing_private_subnet_ids" {
  type = list(string)
}

variable "existing_public_subnet_ids" {
  type = list(string)
}

variable "existing_rds_sg_id" {
  type = string
}

variable "existing_ecs_tasks_sg_id" {
  type = string
}

# ALB SG will be CREATED — NO VARIABLE NEEDED
