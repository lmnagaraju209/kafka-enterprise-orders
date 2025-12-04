terraform {
  backend "s3" {
    # ✅ ASSUMPTION: You already have this bucket in us-east-2:
    #   kafka-enterprise-orders-tfstate
    bucket         = "kafka-enterprise-orders-tfstate"
    key            = "terraform.tfstate"
    region         = "us-east-2"

    # ✅ You showed this DynamoDB table in us-east-2:
    #   kafka-enterprise-orders-lock
    dynamodb_table = "kafka-enterprise-orders-lock"

    encrypt = true
  }
}

