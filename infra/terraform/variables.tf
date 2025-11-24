variable "aws_region" {
  type = string
}

variable "project_name" {
  type    = string
  default = "kafka-enterprise-orders"
}

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

# Confluent
variable "confluent_bootstrap_servers" {
  type = string
}
variable "confluent_api_key" {
  type = string
}
variable "confluent_api_secret" {
  type = string
}

# Kafka topics
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

# Couchbase
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
  type    = string
  default = "password"
}

# RDS
variable "rds_password" {
  type      = string
  sensitive = true
}
