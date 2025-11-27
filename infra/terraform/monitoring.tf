###############################################
# ALB CLOUDWATCH ALARMS
###############################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "missing"

  dimensions = {
    LoadBalancer = aws_lb.ecs_alb.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${local.project_name}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "missing"

  dimensions = {
    LoadBalancer = aws_lb.ecs_alb.arn_suffix
  }
}
