variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
}

variable "public_subnet_cidr_block" {
    type = list
    description = "CIDR block for Public Subnet"
}

variable "eks_private_subnet_cidr_block" {
    type = list
    description = "CIDR block for EKS Private Subnet"
}

variable "env" {
    description = "Environment"
    type = string
    default = "development"
}
