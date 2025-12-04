###############################################
# ECS CLUSTER
###############################################
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

###############################################
# IAM ROLE FOR ECS TASK EXECUTION
###############################################
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_1" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###############################################
# SECURITY GROUP FOR ECS TASKS (WORKERS)
###############################################
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = local.vpc_id # you already have local.vpc_id in locals.tf

  # Workers do not accept inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["127.0.0.1/32"]
  }

  # Outbound to internet (Confluent Cloud, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
# CLOUDWATCH LOG GROUPS
###############################################
resource "aws_cloudwatch_log_group" "producer_lg" {
  name              = "/ecs/${var.project_name}-producer"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "fraud_lg" {
  name              = "/ecs/${var.project_name}-fraud"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "payment_lg" {
  name              = "/ecs/${var.project_name}-payment"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "analytics_lg" {
  name              = "/ecs/${var.project_name}-analytics"
  retention_in_days = 1
}

###############################################
# TASK DEFINITIONS – PRODUCER / FRAUD / PAYMENT / ANALYTICS
###############################################

# PRODUCER – sends messages to Kafka (Confluent Cloud)
resource "aws_ecs_task_definition" "producer" {
  family                   = "${var.project_name}-producer"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = var.container_image_producer
      essential = true

      environment = [
        { name = "SERVICE_NAME",           value = "producer" },
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY",       value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET",    value = var.confluent_api_secret },
        { name = "TOPIC_NAME",              value = "orders" },
        { name = "SLEEP_SECONDS",           value = "2" }
      ]

      # no portMappings – this is a background worker, no HTTP

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.producer_lg.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# FRAUD SERVICE – consumes from Kafka, flags suspicious orders
resource "aws_ecs_task_definition" "fraud" {
  family                   = "${var.project_name}-fraud"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "fraud"
      image     = var.container_image_fraud
      essential = true

      environment = [
        { name = "SERVICE_NAME",           value = "fraud-service" },
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY",       value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET",    value = var.confluent_api_secret },
        { name = "INPUT_TOPIC",             value = "orders" }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fraud_lg.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# PAYMENT SERVICE – consumes from Kafka, simulates payments
resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project_name}-payment"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "payment"
      image     = var.container_image_payment
      essential = true

      environment = [
        { name = "SERVICE_NAME",           value = "payment-service" },
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY",       value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET",    value = var.confluent_api_secret },
        { name = "INPUT_TOPIC",             value = "orders" }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.payment_lg.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ANALYTICS SERVICE – consumes from Kafka, writes to Couchbase / DB
resource "aws_ecs_task_definition" "analytics" {
  family                   = "${var.project_name}-analytics"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "analytics"
      image     = var.container_image_analytics
      essential = true

      environment = [
        { name = "SERVICE_NAME",           value = "analytics-service" },
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY",       value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET",    value = var.confluent_api_secret },
        { name = "INPUT_TOPIC",             value = "orders" },
        # add Couchbase / DB envs here if needed
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.analytics_lg.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

###############################################
# ECS SERVICES – 4 WORKERS, NO ALB
###############################################

resource "aws_ecs_service" "producer" {
  name            = "${var.project_name}-producer-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnets  # from your locals.tf
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true                 # needs internet for Confluent Cloud
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_1,
    aws_cloudwatch_log_group.producer_lg
  ]
}

resource "aws_ecs_service" "fraud" {
  name            = "${var.project_name}-fraud-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_1,
    aws_cloudwatch_log_group.fraud_lg
  ]
}

resource "aws_ecs_service" "payment" {
  name            = "${var.project_name}-payment-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_1,
    aws_cloudwatch_log_group.payment_lg
  ]
}

resource "aws_ecs_service" "analytics" {
  name            = "${var.project_name}-analytics-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.public_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_1,
    aws_cloudwatch_log_group.analytics_lg
  ]
}

