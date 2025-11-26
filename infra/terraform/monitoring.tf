##############################################
# RDS — HIGH CPU ALARM
##############################################

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  alarm_description   = "RDS CPU above 80%"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.orders_db.id
  }
}

##############################################
# RDS — CPU NORMAL
##############################################

resource "aws_cloudwatch_metric_alarm" "rds_cpu_normal" {
  alarm_name          = "${var.project_name}-rds-cpu-normal"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 60

  alarm_description   = "RDS CPU is normal"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.orders_db.id
  }
}

##############################################
# ALB — HIGH 5xx ERRORS
##############################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10

  alarm_description = "ALB is returning high 5xx errors"

  dimensions = {
    LoadBalancer = aws_lb.webapp_alb.arn_suffix
  }
}

##############################################
# ALB — HIGH LATENCY
##############################################

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.project_name}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.5

  alarm_description = "ALB latency too high"

  dimensions = {
    LoadBalancer = aws_lb.webapp_alb.arn_suffix
  }
}
