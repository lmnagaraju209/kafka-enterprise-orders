variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "keo-eks"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.20.3.0/24", "10.20.4.0/24"]
}

# GHCR Credentials
variable "ghcr_username" {
  type        = string
  default     = "aisalkyn85"
  description = "GitHub username for GHCR"
}

variable "ghcr_pat" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with read:packages scope"
}

# App Domain
variable "app_domain" {
  type        = string
  default     = "orders.jumptotech.net"
  description = "Domain for the webapp"
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN for HTTPS"
}

# Couchbase
variable "couchbase_host" {
  type        = string
  default     = "cb.2s2wqp2fpzi0hanx.cloud.couchbase.com"
  description = "Couchbase Capella host"
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
  description = "Couchbase password"
}
