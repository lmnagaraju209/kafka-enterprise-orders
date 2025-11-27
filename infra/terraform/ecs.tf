###############################################
# ECS CLUSTER
###############################################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

###############################################
# IAM ROLE FOR ECS TASKS
###############################################
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

###############################################
# ORDER PRODUCER
###############################################
resource "aws_ecs_task_definition" "producer" {
  family                   = "order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "order-producer"
      image = var.container_image_producer
      essential = true

      portMappings = [{
        containerPort = 8080
        protocol      = "tcp"
      }]
    }
  ])
}

resource "aws_ecs_service" "producer" {
  name            = "order-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1

  network_configuration {
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "order-producer"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.producer_rule]
}

###############################################
# FRAUD SERVICE
###############################################
resource "aws_ecs_task_definition" "fraud" {
  family = "fraud-service"
  network_mode = "awsvpc"
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

      portMappings = [{
        containerPort = 8080
      }]
    }
  ])
}

resource "aws_ecs_service" "fraud" {
  name            = "fraud-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1

  network_configuration {
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fraud_tg.arn
    container_name   = "fraud-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.fraud_rule]
}

###############################################
# PAYMENT SERVICE
###############################################
resource "aws_ecs_task_definition" "payment" {
  family = "payment-service"
  network_mode = "awsvpc"
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

      portMappings = [{
        containerPort = 8080
      }]
    }
  ])
}

resource "aws_ecs_service" "payment" {
  name            = "payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1

  network_configuration {
    subnets          = var.existing_private_subnet_ids_
