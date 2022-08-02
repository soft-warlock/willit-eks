variable "env" {
    description = "Environment"
    type = string
    default = "development"
}

variable "name" {
    // EKS Cluster Name
    default = "development-cluster"
}


variable "instance_types" {
  type        = list
  description = "VPC Development ID"
  default     = ["t3.medium"]
}

variable "vpc_id" {
  type        = string
  description = "VPC Development ID"
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = list
}

variable "eks_subnet_id" {
  description = "EKS Private subnets ID"
  type        = list
}

variable "desired_size" {
  description = "Desired size of node"
  type        = number
  default     = 3
}

variable "max_size" {
  description = "Maximum size of node"
  type        = number
  default = 6
}

variable "min_size" {
  description = "Minimum size of node"
  type        = number
  default     = 3
}

variable "security_group_ids" {
  description = "The security groups to access EKS"
  type        = list
  default     = []
}

variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.22.11-eksbuild.2"
    },
    {
      name    = "vpc-cni"
      version = "v1.11.2-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.8.7-eksbuild.1"
    }
#    {
#      name    = "aws-ebs-csi-driver"
#      version = "v1.6.0-eksbuild.1"
#    }
  ]
}
