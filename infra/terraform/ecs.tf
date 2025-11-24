########################################
# ECS Cluster
########################################

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

########################################
# ECS Security Group (FIXED HERE)
########################################

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

########################################
# IAM ROLES
########################################

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

########################################
# CLOUDWATCH LOG GROUPS
########################################

resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/${var.project_name}-producer"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fraud" {
  name              = "/ecs/${var.project_name}-fraud"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "payment" {
  name              = "/ecs/${var.project_name}-payment"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "analytics" {
  name              = "/ecs/${var.project_name}-analytics"
  retention_in_days = 7
}

########################################
# TASK DEFINITIONS
########################################

resource "aws_ecs_task_definition" "order_producer" {
  family                   = "${var.project_name}-producer"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "order-producer"
      image     = var.container_image_producer
      essential = true
      environment = [
        { name = "ORDERS_TOPIC", value = var.orders_topic },
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY", value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET", value = var.confluent_api_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.producer.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "producer"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "fraud_service" {
  family                   = "${var.project_name}-fraud"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "fraud-service"
      image     = var.container_image_fraud
      essential = true
      environment = [
        { name = "ORDERS_TOPIC", value = var.orders_topic },
        { name = "FRAUD_ALERTS_TOPIC", value = var.fraud_alerts_topic },
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY", value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET", value = var.confluent_api_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fraud.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "fraud"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "payment_service" {
  family                   = "${var.project_name}-payment"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "payment-service"
      image     = var.container_image_payment
      essential = true
      environment = [
        { name = "PAYMENTS_TOPIC", value = var.payments_topic },
        { name = "ORDERS_TOPIC", value = var.orders_topic },
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY", value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET", value = var.confluent_api_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.payment.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "payment"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "analytics_service" {
  family                   = "${var.project_name}-analytics"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "analytics-service"
      image     = var.container_image_analytics
      essential = true
      environment = [
        { name = "ORDER_ANALYTICS_TOPIC", value = var.order_analytics_topic },
        { name = "COUCHBASE_HOST", value = var.couchbase_host },
        { name = "COUCHBASE_BUCKET", value = var.couchbase_bucket },
        { name = "COUCHBASE_USERNAME", value = var.couchbase_username },
        { name = "COUCHBASE_PASSWORD", value = var.couchbase_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.analytics.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "analytics"
        }
      }
    }
  ])
}

########################################
# ECS Services (USING FIXED SG)
########################################

resource "aws_ecs_service" "order_producer" {
  name            = "${var.project_name}-producer-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [var.public_subnet_a, var.public_subnet_b]
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }
}
