###############################################
# ECS CLUSTER
###############################################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

###############################################
# IAM ROLE FOR TASKS
###############################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

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
# PRODUCER TASK & SERVICE
###############################################

resource "aws_ecs_task_definition" "producer" {
  family                   = "order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "order-producer"
      image     = var.container_image_producer
      essential = true
    }
  ])
}

resource "aws_ecs_service" "producer" {
  name            = "order-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1

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
  family                   = "fraud-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
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
  name            = "fraud-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1

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
  family                   = "payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
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
  name            = "payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1

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
  family                   = "analytics-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
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
  name            = "analytics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg]
    assign_public_ip = false
  }
}
