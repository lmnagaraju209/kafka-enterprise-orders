###############################################
# APPLICATION LOAD BALANCER (EXISTING)
###############################################

data "aws_lb" "webapp_alb" {
  arn = local.alb_arn
}

data "aws_lb_listener" "webapp_listener" {
  arn = local.alb_listener_arn
}

###############################################
# TARGET GROUPS
###############################################

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "payment_tg" {
  name        = "payment-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "analytics_tg" {
  name        = "analytics-tg"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "ip"
}
