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
# IAM ROLES FOR ECS TASKS
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
# CLOUDWATCH LOG GROUPS (FIXED)
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
# PRODUCER TASK DEFINITION
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

########################################
# FRAUD SERVICE TASK DEF
########################################

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

########################################
# PAYMENT SERVICE TASK DEF
########################################

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

########################################
# ANALYTICS SERVICE TASK DEF
########################################

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
# ECS SERVICES
########################################

resource "aws_ecs_service" "order_producer" {
  name            = "${var.project_name}-producer-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [var.public_subnet_a, var.public_subnet_b]
    security_groups = [var.ecs_tasks_sg]
    assign_public_ip = true
  }
}

