output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output cluster_name {
  value = aws_eks_cluster.eks.name
}

output cluster_oidc_issuer_url {
  value = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

output oidc_provider_arn {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

output cluster_id {
  value = aws_eks_cluster.eks.id
}

