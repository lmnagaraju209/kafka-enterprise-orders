###########################################
# ALB 5XX ERROR ALARM
###########################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.ecs_alb.arn_suffix
  }

  alarm_description = "High number of 5XX errors on ALB"
  actions_enabled   = false
}

###########################################
# ALB LATENCY ALARM
###########################################

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.project_name}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.ecs_alb.arn_suffix
  }

  alarm_description = "High latency detected in ALB"
  actions_enabled   = false
}

