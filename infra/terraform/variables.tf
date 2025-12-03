##############################
# VARIABLES FOR TERRAFORM
##############################

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "container_image_producer" {
  type        = string
  description = "Docker image for producer"
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

variable "confluent_bootstrap_servers" {
  type        = string
}

variable "confluent_api_key" {
  type        = string
}

variable "confluent_api_secret" {
  type        = string
}

variable "rds_password" {
  type        = string
}

##############################
# NETWORK (STATIC INPUTS)
##############################

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

