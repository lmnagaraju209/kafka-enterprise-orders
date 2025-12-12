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
