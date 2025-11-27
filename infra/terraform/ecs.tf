###############################################
# ECS CLUSTER
###############################################

resource "aws_ecs_cluster" "main" {
  # use a slightly different name to avoid "already exists"
  name = "${var.project_name}-cluster-main"
}

###############################################
# IAM ROLE FOR TASKS
###############################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role-main"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

###############################################
# COMMON FARGATE SETTINGS
###############################################

locals {
  fargate_cpu    = 256
  fargate_memory = 512
}

###############################################
# PRODUCER SERVICE
###############################################

resource "aws_ecs_task_definition" "producer" {
  family                   = "${var.project_name}-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.fargate_cpu
  memory                   = local.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = var.container_image_producer
      essential = true
      environment = [
        { name = "BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY", value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET", value = var.confluent_api_secret }
      ]
    }
  ])
}

resource "aws_ecs_service" "producer" {
  name            = "${var.project_name}-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg]
    assign_public_ip = false
  }
}

###############################################
# FRAUD SERVICE
###############################################

resource "aws_ecs_task_definition" "fraud" {
  family                   = "${var.project_name}-fraud"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.fargate_cpu
  memory                   = local.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "fraud-service"
      image     = var.container_image_fraud
      essential = true
    }
  ])
}

resource "aws_ecs_service" "fraud" {
  name            = "${var.project_name}-fraud"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg]
    assign_public_ip = false
  }
}

###############################################
# PAYMENT SERVICE
###############################################

resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project_name}-payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.fargate_cpu
  memory                   = local.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "payment-service"
      image     = var.container_image_payment
      essential = true
    }
  ])
}

resource "aws_ecs_service" "payment" {
  name            = "${var.project_name}-payment"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg]
    assign_public_ip = false
  }
}

###############################################
# ANALYTICS SERVICE
###############################################

resource "aws_ecs_task_definition" "analytics" {
  family                   = "${var.project_name}-analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.fargate_cpu
  memory                   = local.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "analytics-service"
      image     = var.container_image_analytics
      essential = true
    }
  ])
}

resource "aws_ecs_service" "analytics" {
  name            = "${var.project_name}-analytics"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg]
    assign_public_ip = false
  }
}
