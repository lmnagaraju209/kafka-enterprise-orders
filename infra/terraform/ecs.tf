###############################################
# ECS CLUSTER
###############################################
# Reuse the original name "main" so Terraform
# stops trying to destroy/recreate another cluster.
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

###############################################
# IAM ROLE FOR ECS TASK EXECUTION
###############################################
# Keep the same logical name as before to match state.
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
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###############################################
# SECURITY GROUP FOR ECS TASKS
###############################################
# New SG name to avoid conflict with any old ones.
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = local.vpc_id

  # Allow ALB to reach tasks on 8080
  ingress {
    description     = "Allow ALB to reach tasks"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [local.alb_sg]
  }

  # Allow tasks to talk out (e.g. to Confluent Cloud)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
# CLOUDWATCH LOG GROUP FOR PRODUCER
###############################################
# Use a NEW name so we don't hit "already exists".
resource "aws_cloudwatch_log_group" "producer_lg" {
  name              = "/ecs/${var.project_name}-producer-app"
  retention_in_days = 1
}

###############################################
# ECS TASK DEFINITION – PRODUCER
###############################################
resource "aws_ecs_task_definition" "producer" {
  family                   = "${var.project_name}-producer"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = var.container_image_producer
      essential = true

      environment = [
        { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.confluent_bootstrap_servers },
        { name = "CONFLUENT_API_KEY",       value = var.confluent_api_key },
        { name = "CONFLUENT_API_SECRET",    value = var.confluent_api_secret },
        { name = "TOPIC_NAME",              value = "orders" },
        { name = "SLEEP_SECONDS",           value = "2" }
      ]

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

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

###############################################
# ECS SERVICE – PRODUCER
###############################################
resource "aws_ecs_service" "producer" {
  name            = "${var.project_name}-producer-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "producer"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_role_attach,
    aws_cloudwatch_log_group.producer_lg,
    aws_lb_listener.http
  ]
}

