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
# LISTENER (HTTP PORT 80)
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

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id
}

###############################################
# LISTENER ROUTING RULES
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
    target_group_arn = aws_lb_target_group.backend_tg.arn
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
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  condition {
    path_pattern { values = ["/*"] }
  }
}
