aws_region   = "us-east-2"
project_name = "kafka-enterprise-orders"

# ghcr - set via TF_VAR_ghcr_pat env var
ghcr_username = "aisalkyn85"
ghcr_pat      = ""

# network
existing_vpc_id = "vpc-049d13a5b8edff90c"

existing_public_subnet_ids = [
  "subnet-089bce5034a365097",
  "subnet-080807a84abb68f7a"
]

existing_private_subnet_ids = [
  "subnet-0dffaeb3a77645fee",
  "subnet-0077b9567f697e02a"
]

existing_alb_sg_id       = "sg-01f5a50e367b80a8a"
existing_ecs_tasks_sg_id = "sg-063408014f4646f7a"
existing_rds_sg_id       = "sg-0017c926dac825e6a"

# container images
container_image_producer  = "ghcr.io/aisalkyn85/kafka-enterprise-orders-producer:latest"
container_image_fraud     = "ghcr.io/aisalkyn85/kafka-enterprise-orders-fraud-service:latest"
container_image_payment   = "ghcr.io/aisalkyn85/kafka-enterprise-orders-payment-service:latest"
container_image_analytics = "ghcr.io/aisalkyn85/kafka-enterprise-orders-analytics-service:latest"
container_image_frontend  = "ghcr.io/aisalkyn85/kafka-enterprise-orders/web-frontend:latest"
container_image_backend   = "ghcr.io/aisalkyn85/kafka-enterprise-orders/web-backend:latest"

# confluent - set via TF_VAR_ env vars
confluent_bootstrap_servers = ""
confluent_api_key           = ""
confluent_api_secret        = ""

# couchbase - set via TF_VAR_ env vars
couchbase_host     = ""
couchbase_bucket   = "order_analytics"
couchbase_username = "Administrator"
couchbase_password = ""
