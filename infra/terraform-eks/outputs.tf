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

