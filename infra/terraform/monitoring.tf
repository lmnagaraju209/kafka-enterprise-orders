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
  statistic           = "Average"     # REQUIRED FIX
  threshold           = 80

  alarm_description   = "RDS CPU above 80%"
  alarm_actions       = []
  ok_actions          = []
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

##############################################
# RDS — CPU RECOVERY ALARM
##############################################

resource "aws_cloudwatch_metric_alarm" "rds_cpu_normal" {
  alarm_name          = "${var.project_name}-rds-cpu-normal"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"   # REQUIRED FIX
  threshold           = 60

  alarm_description   = "RDS CPU returned to normal"
  alarm_actions       = []
  ok_actions          = []
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

##############################################
# ECS SERVICE — HIGH CPU ALARM
##############################################

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"   # FIX
  threshold           = 75

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.order_producer.name
  }
}

##############################################
# ECS SERVICE — HIGH MEMORY ALARM
##############################################

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"   # FIX
  threshold           = 75

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.order_producer.name
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
  statistic           = "Sum"     # FIX
  threshold           = 10

  dimensions = {
    LoadBalancer = aws_lb.webapp_alb.arn_suffix
  }
}

##############################################
# ALB — HIGH LATENCY
##############################################

resource "aws_cloudwatch_metric_alarm" "alb_high_latency" {
  alarm_name          = "${var.project_name}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"   # FIX
  threshold           = 0.5

  dimensions = {
    LoadBalancer = aws_lb.webapp_alb.arn_suffix
  }
}
