##############################
# CONTAINER IMAGES
##############################
variable "container_image_producer" {
  description = "Docker image for producer service"
  type        = string
}

variable "container_image_fraud" {
  description = "Docker image for fraud service"
  type        = string
}

variable "container_image_payment" {
  description = "Docker image for payment service"
  type        = string
}

variable "container_image_analytics" {
  description = "Docker image for analytics service"
  type        = string
}

##############################
# KAFKA / CONFLUENT CLOUD
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

