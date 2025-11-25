########################################
# ECS TASKS SECURITY GROUP (private)
########################################

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  # ECS tasks DO NOT accept traffic from internet.
  # They only accept traffic from internal ALB (if used).
  ingress {
    description      = "Allow traffic from ALB only"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]  # created below
  }

  # Allow tasks to make outbound requests (Kafka, Confluent, RDS, Internet if NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# ALB SECURITY GROUP (optional but recommended)
########################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # If you want HTTPS later:
  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# RDS SECURITY GROUP (private only)
########################################

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow DB access from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description    = "PostgreSQL access from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
