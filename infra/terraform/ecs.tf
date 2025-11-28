###############################################
# ECS CLUSTER
###############################################

resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Project = local.project_name
  }
}

###############################################
# IAM ROLE FOR TASK EXECUTION
###############################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Project = local.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###############################################
# TASK DEFINITIONS (BACKEND MICROSERVICES)
###############################################

# Producer
resource "aws_ecs_task_definition" "producer" {
  family                   = "${local.project_name}-producer"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "producer"
    image     = var.container_image_producer
    essential = true
    environment = [
      { name = "BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
      { name = "API_KEY",            value = var.confluent_api_key },
      { name = "API_SECRET",         value = var.confluent_api_secret }
    ]
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
  }])

  tags = {
    Project = local.project_name
  }
}

# Fraud
resource "aws_ecs_task_definition" "fraud" {
  family                   = "${local.project_name}-fraud"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "fraud"
    image     = var.container_image_fraud
    essential = true
    environment = [
      { name = "BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
      { name = "API_KEY",            value = var.confluent_api_key },
      { name = "API_SECRET",         value = var.confluent_api_secret }
    ]
  }])

  tags = {
    Project = local.project_name
  }
}

# Payment
resource "aws_ecs_task_definition" "payment" {
  family                   = "${local.project_name}-payment"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "payment"
    image     = var.container_image_payment
    essential = true
    environment = [
      { name = "BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
      { name = "API_KEY",            value = var.confluent_api_key },
      { name = "API_SECRET",         value = var.confluent_api_secret }
    ]
  }])

  tags = {
    Project = local.project_name
  }
}

# Analytics
resource "aws_ecs_task_definition" "analytics" {
  family                   = "${local.project_name}-analytics"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "analytics"
    image     = var.container_image_analytics
    essential = true
    environment = [
      { name = "BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
      { name = "API_KEY",            value = var.confluent_api_key },
      { name = "API_SECRET",         value = var.confluent_api_secret }
    ]
  }])

  tags = {
    Project = local.project_name
  }
}

###############################################
# ECS SERVICES (private subnets + ECS SG)
###############################################

resource "aws_ecs_service" "producer" {
  name            = "${local.project_name}-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.private_subnets
    security_groups = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_role_attach]

  tags = {
    Project = local.project_name
  }
}

resource "aws_ecs_service" "fraud" {
  name            = "${local.project_name}-fraud"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.private_subnets
    security_groups = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_role_attach]

  tags = {
    Project = local.project_name
  }
}

resource "aws_ecs_service" "payment" {
  name            = "${local.project_name}-payment"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.private_subnets
    security_groups = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_role_attach]

  tags = {
    Project = local.project_name
  }
}

resource "aws_ecs_service" "analytics" {
  name            = "${local.project_name}-analytics"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.private_subnets
    security_groups = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_role_attach]

  tags = {
    Project = local.project_name
  }
}

