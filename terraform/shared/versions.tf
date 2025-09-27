# CKS-focused Terraform provider versions for AWS

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# AWS provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Kubernetes provider - configured after EKS cluster creation
provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
}

# Helm provider - configured after EKS cluster creation
provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
  }
}

# kubectl provider - configured after EKS cluster creation
provider "kubectl" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
  load_config_file       = false
}

# Data sources for EKS cluster (when cluster exists)
data "aws_eks_cluster" "cluster" {
  count = var.create_eks_cluster ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.create_eks_cluster ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks"
}