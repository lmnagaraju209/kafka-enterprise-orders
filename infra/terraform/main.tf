############################################
# TERRAFORM SETUP + REMOTE BACKEND
############################################
terraform {
  required_version = ">= 1.5.0"

  # Remote backend in S3 (for CI/CD + team use)
  backend "s3" {
    bucket         = "kafka-enterprise-orders-tfstate"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################################
# AWS PROVIDER
############################################
provider "aws" {
  region = var.aws_region
}

