###############################################
# NETWORK VALUES (STATIC)
###############################################

vpc_id = "vpc-049d13a5b8edff90c"

public_subnets = [
  "subnet-089bce5034a365097",
  "subnet-080807a84abb68f7a"
]

private_subnets = [
  "subnet-0dffaeb3a77645fee",
  "subnet-0077b9567f697e02a"
]

# Security groups
alb_sg_id       = "sg-01f5a50e367b80a8a"
ecs_tasks_sg_id = "sg-063408014f4646f7a"

###############################################
# IMAGES — Populated by GitHub Actions
###############################################

container_image_producer  = ""
container_image_fraud     = ""
container_image_payment    = ""
container_image_analytics  = ""
container_image_backend    = ""
container_image_frontend   = ""

###############################################
# KAFKA / CONFLUENT CLOUD
###############################################

confluent_bootstrap_servers = ""
confluent_api_key           = ""
confluent_api_secret        = ""

###############################################
# RDS PASSWORD
###############################################

rds_password = ""

