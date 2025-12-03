locals {
  project_name = var.project_name
}

resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.project_name}"
  retention_in_days = 7
}

###############
#  TASK DEFINITIONS
###############

resource "aws_ecs_task_definition" "producer" {
  family                   = "${local.project_name}-producer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "producer"
      image = var.container_image_producer
      essential = true

      environment = [
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = var.confluent_bootstrap_servers
        },
        {
          name  = "CONFLUENT_API_KEY"
          value = var.confluent_api_key
        },
        {
          name  = "CONFLUENT_API_SECRET"
          value = var.confluent_api_secret
        },
        {
          name  = "TOPIC_NAME"
          value = "orders"
        },
        {
          name  = "SLEEP_SECONDS"
          value = "2"
        }
      ]

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "producer"
        }
      }
    }
  ])
}

###############
#  TARGET GROUP
###############

resource "aws_lb_target_group" "producer_tg" {
  name        = "${local.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

###############
#  ECS SERVICE
###############

resource "aws_ecs_service" "producer" {
  name            = "${local.project_name}-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "producer"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}

###############
# IAM ROLES
###############

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

