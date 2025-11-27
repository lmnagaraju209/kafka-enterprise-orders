###############################################
# MONITORING — CLEANED VERSION
# ALB MONITORING REMOVED (NO ALB DATA SOURCE)
###############################################

# Example ECS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }

  alarm_description = "ECS CPU usage is too high."
}
