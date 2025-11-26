##############################################
# ECS AUTOSCALING TARGET
##############################################

resource "aws_appautoscaling_target" "order_producer" {
  max_capacity       = 4
  min_capacity       = 1

  # Must match the real ECS cluster & ECS service names
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.order_producer.name}"

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

##############################################
# SCALE UP POLICY
##############################################

resource "aws_appautoscaling_policy" "order_producer_scale_up" {
  name               = "${var.project_name}-order-producer-scale-up"
  policy_type        = "StepScaling"

  resource_id        = aws_appautoscaling_target.order_producer.resource_id
  scalable_dimension = aws_appautoscaling_target.order_producer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.order_producer.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 60

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
    }
  }
}

##############################################
# SCALE DOWN POLICY
##############################################

resource "aws_appautoscaling_policy" "order_producer_scale_down" {
  name               = "${var.project_name}-order-producer-scale-down"
  policy_type        = "StepScaling"

  resource_id        = aws_appautoscaling_target.order_producer.resource_id
  scalable_dimension = aws_appautoscaling_target.order_producer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.order_producer.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 120

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0
    }
  }
}
