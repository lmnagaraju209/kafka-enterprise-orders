output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc" {
  value = module.eks.cluster_oidc_issuer_url
}

output "node_group_role" {
  value = module.eks.eks_managed_node_groups["general"].iam_role_arn
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}"
}

output "argocd_url" {
  value = "kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_password" {
  value = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
