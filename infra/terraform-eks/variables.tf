variable "aws_region" {
  type = string
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
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

