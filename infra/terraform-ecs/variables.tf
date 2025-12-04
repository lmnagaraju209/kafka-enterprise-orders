variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  default     = "kafka-enterprise-orders-eks-cluster"
}

variable "project_name" {
  type        = string
  default     = "kafka-enterprise-orders"
}

