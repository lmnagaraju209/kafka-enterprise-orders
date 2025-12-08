variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "kafka-enterprise-orders"
}

variable "cluster_name" {
  type    = string
  default = "kafka-enterprise-orders-eks-cluster"
}

# GHCR - GitHub Container Registry
variable "ghcr_username" {
  type        = string
  description = "GitHub username for GHCR"
}

variable "ghcr_pat" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with read:packages scope (https://github.com/settings/tokens)"
}

# Network
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

# Container images
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

variable "container_image_frontend" {
  type = string
}

variable "container_image_backend" {
  type = string
}

# Confluent Cloud / Kafka
variable "confluent_bootstrap_servers" {
  type        = string
  description = "Confluent Cloud bootstrap server (e.g., pkc-xxxxx.region.aws.confluent.cloud:9092)"
}

variable "confluent_api_key" {
  type        = string
  sensitive   = true
  description = "Confluent Cloud API key"
}

variable "confluent_api_secret" {
  type        = string
  sensitive   = true
  description = "Confluent Cloud API secret"
}

# Couchbase Capella
variable "couchbase_host" {
  type        = string
  description = "Couchbase Capella host (e.g., cb.xxxxx.cloud.couchbase.com)"
}

variable "couchbase_bucket" {
  type    = string
  default = "order_analytics"
}

variable "couchbase_username" {
  type    = string
  default = "admin"
}

variable "couchbase_password" {
  type        = string
  sensitive   = true
  description = "Couchbase database password"
}
