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
# IAM Roles for ECS Tasks
########################################

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

########################################
# CloudWatch Log Groups (created, NOT data source)
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
# ORDER PRODUCER ECS TASK
########################################

resource "aws_ecs_task_definition" "order_producer" {
  family                   = "${var.project_name}-order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "order-producer"
      image     = var.container_image_producer
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.producer.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY", value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET", value = var.confluent_api_secret },
        { name = "ORDERS_TOPIC", value = var.orders_topic }
      ]
    }
  ])
}

resource "aws_ecs_service" "order_producer" {
  name            = "${var.project_name}-order-producer"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }
}

########################################
# FRAUD SERVICE
########################################

resource "aws_ecs_task_definition" "fraud_service" {
  family                   = "${var.project_name}-fraud-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "fraud-service"
      image     = var.container_image_fraud
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.fraud.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY", value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET", value = var.confluent_api_secret },
        { name = "ORDERS_TOPIC", value = var.orders_topic },
        { name = "FRAUD_ALERTS_TOPIC", value = var.fraud_alerts_topic }
      ]
    }
  ])
}

########################################
# PAYMENT SERVICE
########################################

resource "aws_ecs_task_definition" "payment_service" {
  family                   = "${var.project_name}-payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "payment-service"
      image     = var.container_image_payment
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.payment.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY", value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET", value = var.confluent_api_secret },
        { name = "PAYMENTS_TOPIC", value = var.payments_topic }
      ]
    }
  ])
}

########################################
# ANALYTICS SERVICE
########################################

resource "aws_ecs_task_definition" "analytics_service" {
  family                   = "${var.project_name}-analytics-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "analytics-service"
      image     = var.container_image_analytics
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.analytics.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY", value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET", value = var.confluent_api_secret },
        { name = "ORDER_ANALYTICS_TOPIC", value = var.order_analytics_topic },
        { name = "COUCHBASE_HOST", value = var.couchbase_host }
      ]
    }
  ])
}


