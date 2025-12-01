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
# TASK DEFINITIONS
###############################################

### -------- PRODUCER -------- ###
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
      { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
      { name = "ORDERS_TOPIC", value = "orders" },
      { name = "ORDER_PRODUCER_INTERVAL_SECONDS", value = "3" }
    ]

    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${local.project_name}-producer"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Project = local.project_name
  }
}

### -------- FRAUD SERVICE -------- ###
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
      { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
      { name = "ORDERS_TOPIC", value = "orders" },
      { name = "FRAUD_AMOUNT_THRESHOLD", value = "400" },
      { name = "FRAUD_RISKY_COUNTRIES", value = "RU,FR,BR" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${local.project_name}-fraud"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Project = local.project_name
  }
}

### -------- PAYMENT SERVICE -------- ###
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
      { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
      { name = "ORDERS_TOPIC", value = "orders" },
      { name = "PAYMENTS_TOPIC", value = "payments" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${local.project_name}-payment"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Project = local.project_name
  }
}

### -------- ANALYTICS SERVICE -------- ###
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
      { name = "KAFKA_BROKER", value = var.confluent_bootstrap_servers },
      { name = "ORDERS_TOPIC", value = "orders" },
      { name = "ANALYTICS_PRINT_EVERY", value = "10" },

      { name = "COUCHBASE_HOST", value = "couchbase" },
      { name = "COUCHBASE_BUCKET", value = "order_analytics" },
      { name = "COUCHBASE_USERNAME", value = "Administrator" },
      { name = "COUCHBASE_PASSWORD", value = "password" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${local.project_name}-analytics"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Project = local.project_name
  }
}

###############################################
# ECS SERVICES
###############################################

resource "aws_ecs_service" "producer" {
  name            = "${local.project_name}-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_role_attach
  ]
}

resource "aws_ecs_service" "fraud" {
  name            = "${local.project_name}-fraud"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_role_attach
  ]
}

resource "aws_ecs_service" "payment" {
  name            = "${local.project_name}-payment"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_role_attach
  ]
}

resource "aws_ecs_service" "analytics" {
  name            = "${local.project_name}-analytics"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [local.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_role_attach
  ]
}

