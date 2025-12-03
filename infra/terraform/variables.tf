###############################################
# GENERAL
###############################################

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

###############################################
# IMAGES
###############################################

variable "container_image_producer"   { type = string }
variable "container_image_fraud"      { type = string }
variable "container_image_payment"    { type = string }
variable "container_image_analytics"  { type = string }
variable "container_image_backend"    { type = string }
variable "container_image_frontend"   { type = string }

###############################################
# NETWORK INPUTS
###############################################

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

###############################################
# DATABASE
###############################################

variable "rds_password" {
  type = string
}

###############################################
# KAFKA
###############################################

variable "confluent_bootstrap_servers" {
  type = string
}

variable "confluent_api_key" {
  type = string
}

variable "confluent_api_secret" {
  type = string
}

