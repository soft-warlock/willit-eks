terraform {
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Allow any 3.22+  version of the AWS provider
    version = "4.12.1"
    }
    null = {
    source = "hashicorp/null"
    version = "~> 3.0"
    }
    external = {
    source = "hashicorp/external"
    version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig"
  }
}
