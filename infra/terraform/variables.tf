###############################################
# NETWORK
###############################################
variable "existing_vpc_id" {
  type = string
}

variable "existing_private_subnet_ids" {
  type = list(string)
}

variable "existing_public_subnet_ids" {
  type = list(string)
}

###############################################
# SECURITY GROUPS
###############################################
variable "existing_ecs_tasks_sg_id" {
  type = string
}

variable "existing_rds_sg_id" {
  type = string
}

variable "existing_alb_sg_id" {
  type = string
}

###############################################
# DOCKER IMAGES
###############################################
variable "container_image_producer" { type = string }
variable "container_image_fraud"    { type = string }
variable "container_image_payment"  { type = string }
variable "container_image_analytics" { type = string }
variable "web_backend_image"        { type = string }
variable "web_frontend_image"       { type = string }

###############################################
# RDS PASSWORD
###############################################
variable "rds_password" {
  type = string
}

###############################################
# CONFLUENT INPUT
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

###############################################
# PROJECT NAME
###############################################
variable "project_name" {
  type = string
  default = "kafka-enterprise-orders"
}
