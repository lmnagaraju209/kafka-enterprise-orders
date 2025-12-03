output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.ecs_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.ecs_alb.arn
}

