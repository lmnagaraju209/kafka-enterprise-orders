terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"   # 🔒 stay on 5.x to avoid the identity/account_id bug
    }
  }
}

provider "aws" {
  region = var.aws_region  # from terraform.tfvars → us-east-2
}

