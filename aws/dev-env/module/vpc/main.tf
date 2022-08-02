# Get current region
data "aws_region" "current" {}

# Get all AZ data
data "aws_availability_zones" "azs" {
    # We need only 2 Availability Zones, you can remove this line if want to use All AZs
    exclude_names = [ "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f" ]
}

locals {
  # Save the data of AZs  to local value
  az_names = data.aws_availability_zones.azs.names
  # Save the eks cluster name to local value
  eks_cluster_name = "development-cluster"
}


# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
  }
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.env}-igw"
    Environment = var.env
  }
}

# EIP for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  for_each   = {for idx, az_name in local.az_names: idx => az_name}
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name        = "${var.env}-eip-nat-${element(local.az_names, each.key)}"
    Environment = var.env
  }
}

# NAT
resource "aws_nat_gateway" "nat_gateway" {
  for_each      = {for idx, az_name in local.az_names: idx => az_name}
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.public_subnet[each.key].id

  tags = {
    Name        = "${var.env}-nat-gateway-${element(local.az_names, each.key)}"
    Environment = var.env
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
    for_each                = {for idx, az_name in local.az_names: idx => az_name}
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = element(var.public_subnet_cidr_block, each.key)
    availability_zone       = local.az_names[each.key]
    map_public_ip_on_launch = true

    tags = {
        Name                                              = "${var.env}-subnet-public-${element(local.az_names, each.key)}"
        Environment                                       = "${var.env}"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb"                          = "1"
  }
}

# Private subnet
resource "aws_subnet" "eks_subnet" {
    for_each                = {for idx, az_name in local.az_names: idx => az_name}
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = element(var.eks_private_subnet_cidr_block, each.key)
    availability_zone       = local.az_names[each.key]
     map_public_ip_on_launch = false

     tags = {
        Name                                              = "${var.env}-eks-subnet-private-${element(local.az_names, each.key)}"
        Environment                                       = "${var.env}"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb"                 = "1"
    }
}

# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  for_each      = {for idx, az_name in local.az_names: idx => az_name}
  vpc_id        = aws_vpc.vpc.id

  tags = {
    Name        = "${var.env}-rtb-private-${element(local.az_names, each.key)}"
    Environment = "${var.env}"
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id        = aws_vpc.vpc.id

  tags = {
    Name        = "${var.env}-rtb-public"
    Environment = "${var.env}"
  }
}

# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
    for_each               = {for idx, az_name in local.az_names: idx => az_name}
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.internet_gateway.id

    
}

# Route for NAT 
resource "aws_route" "private_nat_gateway" {
    for_each               = {for idx, az_name in local.az_names: idx => az_name}
    route_table_id         = aws_route_table.private[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gateway[each.key].id
    
}

# Route table associations for Public Subnets
resource "aws_route_table_association" "public_rtb" {
    for_each       = {for idx, az_name in local.az_names: idx => az_name}
    subnet_id      = aws_subnet.public_subnet[each.key].id
    route_table_id = aws_route_table.public.id
}

# Route table associations for EKS Subnets
resource "aws_route_table_association" "eks_private_rtb" {
    for_each       = {for idx, az_name in local.az_names: idx => az_name}
    subnet_id      = aws_subnet.eks_subnet[each.key].id
    route_table_id = aws_route_table.private[each.key].id
}

# Default Security Group of VPC
resource "aws_security_group" "security_group" {
  name        = "${var.env}-default-sg"
  description = "Default SG to allow traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [
    aws_vpc.vpc
  ]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Environment = "${var.env}"
  }
}
