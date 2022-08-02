resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.eks.name
  addon_name        = each.value.name
  addon_version = each.value.version
  resolve_conflicts = "OVERWRITE"
}
