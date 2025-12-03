###############################################
# ECS CLUSTER
###############################################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

###############################################
# TASK EXECUTION ROLE
###############################################
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###############################################
# TASK DEFINITIONS
###############################################
resource "aws_ecs_task_definition" "producer" {
  family                   = "${var.project_name}-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "producer"
      image = var.container_image_producer
      essential = true
      portMappings = [{
        containerPort = 8080
        hostPort      = 8080
      }]
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = "prod" }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "fraud" {
  family                   = "${var.project_name}-fraud"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "fraud"
      image = var.container_image_fraud
      essential = true
      portMappings = [{
        containerPort = 8081
        hostPort      = 8081
      }]
    }
  ])
}

resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project_name}-payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "payment"
      image = var.container_image_payment
      essential = true
      portMappings = [{
        containerPort = 8082
        hostPort      = 8082
      }]
    }
  ])
}

resource "aws_ecs_task_definition" "analytics" {
  family                   = "${var.project_name}-analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "analytics"
      image = var.container_image_analytics
      essential = true
      portMappings = [{
        containerPort = 8083
        hostPort      = 8083
      }]
    }
  ])
}

###############################################
# ECS SERVICES (FARGATE)
###############################################
resource "aws_ecs_service" "producer" {
  name            = "${var.project_name}-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.private_subnets
    assign_public_ip = false
    security_groups  = [local.ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "producer"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "fraud" {
  name            = "${var.project_name}-fraud"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.private_subnets
    assign_public_ip = false
    security_groups  = [local.ecs_tasks_sg_id]
  }
}

resource "aws_ecs_service" "payment" {
  name            = "${var.project_name}-payment"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.private_subnets
    assign_public_ip = false
    security_groups  = [local.ecs_tasks_sg_id]
  }
}

resource "aws_ecs_service" "analytics" {
  name            = "${var.project_name}-analytics"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.private_subnets
    assign_public_ip = false
    security_groups  = [local.ecs_tasks_sg_id]
  }
}

