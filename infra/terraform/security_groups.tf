############################################################
# SECURITY GROUPS FOR THE WHOLE PROJECT
############################################################

############################################################
# RDS SECURITY GROUP
# Allows ECS tasks (or entire VPC) to reach PostgreSQL
############################################################

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL from VPC
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound required for DNS, patches, AWS APIs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

############################################################
# ECS TASKS SECURITY GROUP
# ECS tasks need outbound traffic for:
# - Pulling images
# - Talking to Confluent Cloud
# - Connecting to RDS
############################################################

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks in Fargate"
  vpc_id      = aws_vpc.main.id

  # ECS needs outbound internet & VPC access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

############################################################
# ALB SECURITY GROUP (IF YOU HAVE A LOAD BALANCER)
############################################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB ingress security group"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS (optional)
  ingress {
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB -> ECS communication (port 8000 for backend)
  egress {
    description = "Allow ALB to talk to backend"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

############################################################
# OPTIONAL: COUCHBASE SECURITY GROUP (if using self-hosted CB)
############################################################

resource "aws_security_group" "couchbase" {
  count       = 0 # set to 1 if you later deploy Couchbase on EC2
  name        = "${var.project_name}-couchbase-sg"
  description = "Couchbase Server"
  vpc_id      = aws_vpc.main.id

  # Typical Couchbase ports
  ingress {
    from_port   = 8091
    to_port     = 8091
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 11210
    to_port     = 11210
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-couchbase-sg"
  }
}

############################################################
# OPTIONAL FUTURE SGs (Kafka Connect, KSQLDB, etc.)
############################################################

# resource "aws_security_group" "ksqldb" { ... }
# resource "aws_security_group" "kafka_connect" { ... }
