########################################
# General
########################################

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "kafka-enterprise-orders"
}

########################################
# Container Images (passed from CI/CD)
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

########################################
# Confluent Cloud (passed from CI/CD)
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
# RDS CREDENTIALS
########################################

variable "rds_username" {
  type    = string
  default = "orders_user"
}

variable "rds_password" {
  type      = string
  sensitive = true
}
