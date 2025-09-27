# CKS-focused shared Terraform variables for AWS EKS

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (sandbox, local, production)"
  type        = string
  validation {
    condition     = contains(["sandbox", "local", "production"], var.environment)
    error_message = "Environment must be one of: sandbox, local, production."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "linkops-arise"
}

# CKS Security configurations
variable "enable_pod_security_standards" {
  description = "Enable Kubernetes Pod Security Standards"
  type        = bool
  default     = true
}

variable "enable_opa_gatekeeper" {
  description = "Enable OPA Gatekeeper for policy enforcement"
  type        = bool
  default     = true
}

variable "enable_falco" {
  description = "Enable Falco for runtime security monitoring"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable network policies for micro-segmentation"
  type        = bool
  default     = true
}

# AWS Secrets Manager for secrets management
variable "enable_external_secrets" {
  description = "Enable External Secrets Operator with AWS Secrets Manager"
  type        = bool
  default     = true
}

# Monitoring and observability
variable "enable_monitoring_stack" {
  description = "Enable Prometheus/Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "enable_argocd" {
  description = "Enable ArgoCD for GitOps"
  type        = bool
  default     = true
}

# Network configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# EKS cluster configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_config" {
  description = "EKS node group configuration"
  type = object({
    instance_types      = list(string)
    desired_capacity    = number
    min_capacity        = number
    max_capacity        = number
    enable_spot_instances = bool
  })
  default = {
    instance_types       = ["t3.medium"]
    desired_capacity     = 2
    min_capacity         = 1
    max_capacity         = 5
    enable_spot_instances = false
  }
}

# EC2 configuration for practice
variable "ec2_config" {
  description = "EC2 instance configuration for learning"
  type = object({
    instance_type = string
    key_name      = string
  })
  default = {
    instance_type = "t3.micro"
    key_name      = ""  # Will be created
  }
}

# Security configurations
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "enable_private_cluster" {
  description = "Enable private EKS cluster"
  type        = bool
  default     = false
}

# Infrastructure flags
variable "create_eks_cluster" {
  description = "Whether to create EKS cluster"
  type        = bool
  default     = true
}

variable "create_ec2_instance" {
  description = "Whether to create EC2 instance for learning"
  type        = bool
  default     = true
}

# Tags for resource management
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "LinkOps-Arise"
    ManagedBy   = "Terraform"
    Purpose     = "CKS-Demo"
    Environment = "sandbox"
  }
}