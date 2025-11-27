###############################################
# ECS CLUSTER
###############################################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

###############################################
# IAM ROLE FOR TASK EXECUTION
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
# ORDER PRODUCER TASK + SERVICE
###############################################
resource "aws_ecs_task_definition" "producer" {
  family                   = "order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "order-producer"
    image     = var.container_image_producer
    essential = true
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "producer_service" {
  name            = "order-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1

  network_configuration {
    subnets         = var.existing_private_subnet_ids
    security_groups = [var.existing_ecs_tasks_sg_id]
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

  container_definitions = jsonencode([{
    name      = "fraud-service"
    image     = var.container_image_fraud
    essential = true
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "fraud_service" {
  name = "fraud-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count = 1

  network_configuration {
    subnets         = var.existing_private_subnet_ids
    security_groups = [var.existing_ecs_tasks_sg_id]
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

  container_definitions = jsonencode([{
    name      = "payment-service"
    image     = var.container_image_payment
    essential = true
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "payment_service" {
  name = "payment-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count = 1

  network_configuration {
    subnets         = var.existing_private_subnet_ids
    security_groups = [var.existing_ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payment_tg.arn
    container_name   = "payment-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.payment_rule]
}

###############################################
# ANALYTICS SERVICE
###############################################
resource "aws_ecs_task_definition" "analytics" {
  family = "analytics-service"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "analytics-service"
    image     = var.container_image_analytics
    essential = true
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "analytics_service" {
  name = "analytics-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count = 1

  network_configuration {
    subnets         = var.existing_private_subnet_ids
    security_groups = [var.existing_ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.analytics_tg.arn
    container_name   = "analytics-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.analytics_rule]
}

###############################################
# WEB BACKEND
###############################################
resource "aws_ecs_task_definition" "web_backend" {
  family = "web-backend"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "web-backend"
    image     = var.web_backend_image
    essential = true
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "web_backend_service" {
  name = "web-backend"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_backend.arn
  desired_count = 1

  network_configuration {
    subnets         = var.existing_private_subnet_ids
    security_groups = [var.existing_ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_backend_tg.arn
    container_name   = "web-backend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.backend_rule]
}

###############################################
# WEB FRONTEND
###############################################
resource "aws_ecs_task_definition" "web_frontend" {
  family = "web-frontend"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "web-frontend"
    image     = var.web_frontend_image
    essential = true
    portMappings = [{ containerPort = 8080 }]
  }])
}

resource "aws_ecs_service" "web_frontend_service" {
  name = "web-frontend"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_frontend.arn
  desired_count = 1

  network_configuration {
    subnets         = var.existing_private_subnet_ids
    security_groups = [var.existing_ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_frontend_tg.arn
    container_name   = "web-frontend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.frontend_rule]
}
