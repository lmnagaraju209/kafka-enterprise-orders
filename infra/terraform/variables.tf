variable "aws_region" {
  type = string
}

variable "project_name" {
  type    = string
  default = "kafka-enterprise-orders"
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "ecs_tasks_sg_id" {
  type = string
}

variable "container_image_producer" {
  type = string
}

variable "confluent_bootstrap_servers" {
  type = string
}

variable "confluent_api_key" {
  type = string
}

variable "confluent_api_secret" {
  type = string
}

variable "rds_password" {
  type      = string
  sensitive = true
}

