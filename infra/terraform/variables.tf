##############################
# GLOBAL
##############################

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
}

variable "project_name" {
  description = "Base name for ECS/ALB/RDS resources"
  type        = string
  default     = "kafka-enterprise-orders"
}

##############################
# NETWORK (DIRECT VARIABLES)
# These are used by ECS/ALB code
##############################

variable "vpc_id" {
  description = "VPC where ECS and ALB run"
  type        = string
  default     = "vpc-049d13a5b8edff90c"
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
  default     = [
    "subnet-089bce5034a365097",
    "subnet-080807a84abb68f7a",
  ]
}

variable "private_subnets" {
  description = "Private subnets for ECS tasks"
  type        = list(string)
  default     = [
    "subnet-0dffaeb3a77645fee",
    "subnet-0077b9567f697e02a",
  ]
}

variable "alb_sg_id" {
  description = "Security group ID for ALB"
  type        = string
  default     = "sg-01f5a50e367b80a8a"
}

variable "ecs_tasks_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
  default     = "sg-063408014f4646f7a"
}

##############################
# NETWORK (EXISTING_* COMPAT)
# These match values.auto.tfvars file
##############################

variable "existing_vpc_id" {
  description = "Existing VPC id (kept to match values.auto.tfvars)"
  type        = string
  default     = "vpc-049d13a5b8edff90c"
}

variable "existing_public_subnet_ids" {
  description = "Existing public subnet IDs"
  type        = list(string)
  default     = [
    "subnet-089bce5034a365097",
    "subnet-080807a84abb68f7a",
  ]
}

variable "existing_private_subnet_ids" {
  description = "Existing private subnet IDs"
  type        = list(string)
  default     = [
    "subnet-0dffaeb3a77645fee",
    "subnet-0077b9567f697e02a",
  ]
}

variable "existing_alb_sg_id" {
  description = "Existing ALB security group ID"
  type        = string
  default     = "sg-01f5a50e367b80a8a"
}

variable "existing_ecs_tasks_sg_id" {
  description = "Existing ECS tasks security group ID"
  type        = string
  default     = "sg-063408014f4646f7a"
}

variable "existing_rds_sg_id" {
  description = "Existing RDS security group ID"
  type        = string
  default     = "sg-0017c926dac825e6a"
}

##############################
# CONTAINER IMAGES
##############################

variable "container_image_producer" {
  description = "Docker image for producer microservice"
  type        = string
}

variable "container_image_fraud" {
  description = "Docker image for fraud microservice"
  type        = string
}

variable "container_image_payment" {
  description = "Docker image for payment microservice"
  type        = string
}

variable "container_image_analytics" {
  description = "Docker image for analytics microservice"
  type        = string
}

variable "container_image_backend" {
  description = "Docker image for web backend"
  type        = string
}

variable "container_image_frontend" {
  description = "Docker image for web frontend"
  type        = string
}

##############################
# CONFLUENT CLOUD + RDS
##############################

variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud bootstrap servers"
  type        = string
}

variable "confluent_api_key" {
  description = "Confluent Cloud API key"
  type        = string
}

variable "confluent_api_secret" {
  description = "Confluent Cloud API secret"
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "Password for RDS Postgres"
  type        = string
  sensitive   = true
}

