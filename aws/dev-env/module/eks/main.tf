locals {
  name                   = var.name
  vpc_id                 = var.vpc_id
  public_subnet_id       = var.public_subnet_id
  eks_subnet_id          = distinct(flatten(var.eks_subnet_id))
  desired_size           = var.desired_size
  max_size               = var.max_size
  min_size               = var.min_size
  security_group_ids     = var.security_group_ids
}

# Define the role to be attached EKS
resource "aws_iam_role" "eks_cluster_role" {
  name               = "RolesForEKSCluster"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "eks.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# Attach Security Groups for Pods
resource "aws_iam_role_policy_attachment" "eks_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach the EKS Cluster policy to EKS role
resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach the CloudWatchFullAccess policy to EKS role
resource "aws_iam_role_policy_attachment" "eks_CloudWatchFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.eks_cluster_role.name
}

# Default Security Group of EKS
resource "aws_security_group" "security_group" {
  name        = "${var.name} Security Group"
  description = "Default SG to allow traffic from the EKS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = "0"
    to_port         = "0"
    protocol        = "TCP"
    security_groups = var.security_group_ids
  }

  tags = merge({
    Name = "${var.name} Security Group"
  })
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name    = var.name
  version = "1.22"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  role_arn = aws_iam_role.eks_cluster_role.arn

  timeouts {}

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = [
      "0.0.0.0/0",
    ]
    security_group_ids = [
      aws_security_group.security_group.id
    ]
    subnet_ids = flatten([var.eks_subnet_id])
  }

  tags = merge({
    Name = var.name
  })
}

# AWS Load Balancer Controller IAM Policy
resource "aws_iam_policy" "load-balancer-policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"

  policy = file("../module/eks/iam_policy.json")
  
}

resource "aws_iam_role" "node_group_role" {
  name                  = format("%s-node-group-role", lower(aws_eks_cluster.eks.name))
  path                  = "/"
  force_detach_policies = false
  max_session_duration  = 3600
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRole"
          Effect    = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2RoleforSSM" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AWSLoadBalancerControllerPolicy" {
  policy_arn = aws_iam_policy.load-balancer-policy.arn
  role       = aws_iam_role.node_group_role.id
}

resource "aws_eks_node_group" "node_group" {
  cluster_name   = aws_eks_cluster.eks.name
  disk_size      = 20
  ami_type       = "AL2_x86_64"
  instance_types = var.instance_types
  capacity_type  = "ON_DEMAND"
  labels         = {
    "eks/cluster-name"   = aws_eks_cluster.eks.name
    "eks/nodegroup-name" = format("nodegroup_%s", lower(aws_eks_cluster.eks.name))
  }
  node_group_name = format("nodegroup_%s", lower(aws_eks_cluster.eks.name))
  node_role_arn   = aws_iam_role.node_group_role.arn

  subnet_ids = local.eks_subnet_id

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }
  timeouts {}

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({
    Name                 = var.name
    "eks/cluster-name"   = var.name
    "eks/nodegroup-name" = format("%s Node Group", aws_eks_cluster.eks.name)
    "eks/nodegroup-type" = "managed"
  })
}
