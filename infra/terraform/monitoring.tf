resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 2
  period              = 60
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.orders_db.id
  }
}
