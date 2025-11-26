##############################################
# ECS CLUSTER
##############################################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

##############################################
# IAM ROLE FOR ECS TASK EXECUTION
##############################################

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##############################################
# ECS TASK ROLE (MICROSERVICES PERMISSIONS)
##############################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

##############################################
# TASK DEFINITIONS
##############################################

resource "aws_ecs_task_definition" "order_producer" {
  family                   = "${var.project_name}-order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "order-producer"
      image     = var.container_image_producer
      essential = true
      environment = [
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY",   value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET",value = var.confluent_api_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/order-producer"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "fraud_service" {
  family                   = "${var.project_name}-fraud-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "fraud-service"
      image     = var.container_image_fraud
      essential = true
      environment = [
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY",   value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET",value = var.confluent_api_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/fraud-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "payment_service" {
  family                   = "${var.project_name}-payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "payment-service"
      image     = var.container_image_payment
      essential = true
      environment = [
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY",   value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET",value = var.confluent_api_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/payment-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "analytics_service" {
  family                   = "${var.project_name}-analytics-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "analytics-service"
      image     = var.container_image_analytics
      essential = true
      environment = [
        { name = "KAFKA_BOOTSTRAP", value = var.confluent_bootstrap_servers },
        { name = "KAFKA_API_KEY",   value = var.confluent_api_key },
        { name = "KAFKA_API_SECRET",value = var.confluent_api_secret },

        { name = "COUCHBASE_HOST",     value = var.couchbase_host },
        { name = "COUCHBASE_BUCKET",   value = var.couchbase_bucket },
        { name = "COUCHBASE_USERNAME", value = var.couchbase_username },
        { name = "COUCHBASE_PASSWORD", value = var.couchbase_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/analytics-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

##############################################
# ECS SERVICES
##############################################

resource "aws_ecs_service" "order_producer" {
  name            = "${var.project_name}-order-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_execution_role_policy]
}

resource "aws_ecs_service" "fraud_service" {
  name            = "${var.project_name}-fraud-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud_service.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "payment_service" {
  name            = "${var.project_name}-payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment_service.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "analytics_service" {
  name            = "${var.project_name}-analytics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics_service.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}
