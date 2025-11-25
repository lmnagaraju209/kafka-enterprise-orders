########################################
# ECS CLUSTER
########################################

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
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
# IAM ROLES (IDEMPOTENT FOR CI/CD)
########################################

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  lifecycle {
    ignore_changes = [
      name,
      assume_role_policy
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  lifecycle {
    ignore_changes = [
      name,
      assume_role_policy
    ]
  }
}

# Add required permissions for your microservices
resource "aws_iam_role_policy_attachment" "ecs_task_extra" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

########################################
# TASK DEFINITION
########################################

resource "aws_ecs_task_definition" "order_producer" {
  family                   = "${var.project_name}-producer"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "order-producer"
    image     = var.container_image_producer
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

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
  }])

  depends_on = [
    aws_cloudwatch_log_group.producer
  ]
}

########################################
# ECS SERVICE
########################################

resource "aws_ecs_service" "order_producer" {
  name            = "${var.project_name}-producer-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_task_definition.order_producer
  ]
}
