variable "aws_region" {
  type = string
}

variable "project_name" {
  type    = string
  default = "kafka-enterprise-orders"
}

variable "cluster_name" {
  type    = string
  default = "kafka-enterprise-orders-eks-cluster"
}

# ghcr
variable "ghcr_username" {
  type = string
}

variable "ghcr_pat" {
  type      = string
  sensitive = true
}

# network
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

# container images
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

# confluent cloud
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

# couchbase
variable "couchbase_host" {
  type    = string
  default = ""
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
  sensitive = true
  default   = ""
}
