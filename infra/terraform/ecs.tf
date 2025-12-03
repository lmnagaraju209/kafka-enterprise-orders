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
# SECURITY GROUP FOR ECS TASKS
###############################################
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = local.vpc_id

  # ALB -> ECS tasks on 8080
  ingress {
    description     = "Allow ALB to reach tasks"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [local.alb_sg]
  }

  # ECS tasks -> Internet (Confluent Cloud, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

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
          awslogs-group         = "/ecs/${var.project_name}-producer"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

###############################################
# CLOUDWATCH LOG GROUP FOR PRODUCER
###############################################
resource "aws_cloudwatch_log_group" "producer_lg" {
  name              = "/ecs/${var.project_name}-producer"
  retention_in_days = 1
}

###############################################
# ECS SERVICE – PRODUCER
###############################################
resource "aws_ecs_service" "producer" {
  name            = "${var.project_name}-producer-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    # IMPORTANT: use PUBLIC subnets and give PUBLIC IP for internet access
    subnets         = local.public_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "producer"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_1,
    aws_cloudwatch_log_group.producer_lg,
    aws_lb_target_group.producer_tg,
    aws_lb_listener.http
  ]
}

