###############################################
# ECS CLUSTER
###############################################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}


###############################################
# IAM ROLE FOR TASKS
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
# APPLICATION LOAD BALANCER
###############################################
resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_alb_sg_id]
  subnets            = var.existing_public_subnet_ids
}


###############################################
# LISTENER (HTTP 80)
###############################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "Service Online"
    }
  }
}


###############################################
# TARGET GROUPS FOR ALL SERVICES
###############################################
resource "aws_lb_target_group" "producer_tg" {
  name        = "producer-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

resource "aws_lb_target_group" "fraud_tg" {
  name        = "fraud-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

resource "aws_lb_target_group" "payment_tg" {
  name        = "payment-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

resource "aws_lb_target_group" "analytics_tg" {
  name        = "analytics-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

resource "aws_lb_target_group" "web_backend_tg" {
  name        = "web-backend-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

resource "aws_lb_target_group" "web_frontend_tg" {
  name        = "web-frontend-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}


###############################################
# LISTENER RULES (ROUTING)
###############################################
resource "aws_lb_listener_rule" "producer_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer_tg.arn
  }

  condition {
    path_pattern { values = ["/producer/*"] }
  }
}

resource "aws_lb_listener_rule" "fraud_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fraud_tg.arn
  }

  condition {
    path_pattern { values = ["/fraud/*"] }
  }
}

resource "aws_lb_listener_rule" "payment_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_tg.arn
  }

  condition {
    path_pattern { values = ["/payment/*"] }
  }
}

resource "aws_lb_listener_rule" "analytics_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.analytics_tg.arn
  }

  condition {
    path_pattern { values = ["/analytics/*"] }
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_backend_tg.arn
  }

  condition {
    path_pattern { values = ["/api/*"] }
  }
}

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_frontend_tg.arn
  }

  condition {
    path_pattern { values = ["/*"] }
  }
}


###############################################
# TASK DEFINITIONS & SERVICES
###############################################

## ORDER PRODUCER
resource "aws_ecs_task_definition" "producer" {
  family                   = "order-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "order-producer"
    image     = var.container_image_producer
    essential = true
    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
  }])
}

resource "aws_ecs_service" "producer_service" {
  name            = "order-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "order-producer"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.producer_rule]
}


## FRAUD SERVICE
resource "aws_ecs_task_definition" "fraud" {
  family                   = "fraud-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
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
  name            = "fraud-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fraud_tg.arn
    container_name   = "fraud-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.fraud_rule]
}


## PAYMENT SERVICE
resource "aws_ecs_task_definition" "payment" {
  family                   = "payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
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
  name            = "payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payment_tg.arn
    container_name   = "payment-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.payment_rule]
}


## ANALYTICS SERVICE
resource "aws_ecs_task_definition" "analytics" {
  family                   = "analytics-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
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
  name            = "analytics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.analytics_tg.arn
    container_name   = "analytics-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.analytics_rule]
}


## WEB BACKEND
resource "aws_ecs_task_definition" "web_backend" {
  family                   = "web-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
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
  name            = "web-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_backend.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_backend_tg.arn
    container_name   = "web-backend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.backend_rule]
}


## WEB FRONTEND
resource "aws_ecs_task_definition" "web_frontend" {
  family                   = "web-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
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
  name            = "web-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_frontend.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    subnets          = var.existing_private_subnet_ids
    security_groups  = [var.existing_ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_frontend_tg.arn
    container_name   = "web-frontend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.frontend_rule]
}
