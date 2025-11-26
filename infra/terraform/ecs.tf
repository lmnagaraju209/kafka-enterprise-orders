########################################
# ECS Cluster
########################################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

########################################
# Task Execution Role
########################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

########################################
# Task Definitions + Services
########################################

# Producer
resource "aws_ecs_task_definition" "order_producer" {
  family                   = "order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "order-producer"
      image = var.container_image_producer
      essential = true
      environment = [
        { name = "BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "ORDERS_TOPIC", value = var.orders_topic }
      ]
    }
  ])
}

resource "aws_ecs_service" "order_producer" {
  name            = "order-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = local.private_subnets
    security_groups  = [data.aws_security_group.ecs_tasks.id]
  }
}

# Fraud Service
resource "aws_ecs_task_definition" "fraud" {
  family = "fraud-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "fraud-service"
      image = var.container_image_fraud
      essential = true
      environment = [
        { name = "FRAUD_TOPIC", value = var.fraud_alerts_topic }
      ]
    }
  ])
}

resource "aws_ecs_service" "fraud_service" {
  name = "fraud-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count = 1

  network_configuration {
    assign_public_ip = false
    subnets          = local.private_subnets
    security_groups  = [data.aws_security_group.ecs_tasks.id]
  }
}

# Payment service
resource "aws_ecs_task_definition" "payment" {
  family = "payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "payment-service"
      image = var.container_image_payment
      essential = true
    }
  ])
}

resource "aws_ecs_service" "payment_service" {
  name = "payment-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count = 1

  network_configuration {
    assign_public_ip = false
    subnets          = local.private_subnets
    security_groups  = [data.aws_security_group.ecs_tasks.id]
  }
}

# Analytics service
resource "aws_ecs_task_definition" "analytics" {
  family = "analytics-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "analytics-service"
      image = var.container_image_analytics
      essential = true
    }
  ])
}

resource "aws_ecs_service" "analytics_service" {
  name = "analytics-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count = 1

  network_configuration {
    assign_public_ip = false
    subnets          = local.private_subnets
    security_groups  = [data.aws_security_group.ecs_tasks.id]
  }
}
