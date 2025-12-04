output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "producer_service_name" {
  value = aws_ecs_service.producer.name
}

output "fraud_service_name" {
  value = aws_ecs_service.fraud.name
}

output "payment_service_name" {
  value = aws_ecs_service.payment.name
}

output "analytics_service_name" {
  value = aws_ecs_service.analytics.name
}
###############################################
# EKS OUTPUTS
###############################################

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_ca" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

