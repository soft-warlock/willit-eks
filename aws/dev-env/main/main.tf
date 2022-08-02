module "vpc" {
  source                        = "../module/vpc"
  vpc_cidr_block                = "10.230.0.0/19"
  public_subnet_cidr_block      = ["10.230.0.0/24", "10.230.1.0/24"]
  eks_private_subnet_cidr_block = ["10.230.8.0/22", "10.230.12.0/22"]
}

module "eks" {
  source                 = "../module/eks"
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_id
  eks_subnet_id          = module.vpc.eks_subnet_id
}

module "ecr" {
  source = "../module/ecr"
  REPO = var.REPO
}

module "image" {
  source = "../module/docker_image"
  ACCOUNT = module.ecr.ACCOUNT
  REGION = var.REGION
  REPO = var.REPO
  depends_on = [module.ecr]
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = "./"
    command = <<-EOT
    aws eks --region us-east-1 update-kubeconfig --name development-cluster --kubeconfig ${path.module}/kubeconfig
    EOT
  }
  depends_on = [module.eks]
}

module "load_balancer_controller" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"

  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_id
}

#module "helm" {
#  source = "../module/helm"
#  REGION = var.REGION
#  REPO = var.REPO
#  repository_url = module.ecr.repository_url
#  depends_on = [null_resource.kubeconfig]
#}
