# CKS Learning Environment - AWS Sandbox

# Include shared configuration
module "shared_config" {
  source = "../../shared"
}

# Local variables
locals {
  environment    = "sandbox"
  project_name   = "linkops-arise"
  aws_region     = "us-east-1"

  # CKS-focused configurations
  enable_security_features = true

  common_tags = {
    Project     = "LinkOps-Arise"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Purpose     = "CKS-Learning"
    Owner       = "DevOps-Team"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/aws-vpc"

  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Cost optimization: Disable NAT gateways for sandbox
  create_nat_gateways = false

  # Security: Restrict access (replace with your IP)
  allowed_cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to your IP

  common_tags = local.common_tags
}

# EKS Cluster Module
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  project_name   = local.project_name
  environment    = local.environment

  # Cluster configuration
  kubernetes_version = "1.28"

  # Network configuration
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  control_plane_subnet_ids = module.vpc.public_subnet_ids  # Public for sandbox

  # Security groups
  control_plane_security_group_id = module.vpc.eks_control_plane_security_group_id
  node_security_group_id         = module.vpc.eks_nodes_security_group_id

  # Node group configuration (cost-optimized for learning)
  node_groups = {
    main = {
      instance_types   = ["t3.medium"]
      desired_capacity = 2
      min_capacity     = 1
      max_capacity     = 3

      # Cost optimization
      capacity_type = "SPOT"

      # Labels for CKS scenarios
      k8s_labels = {
        role        = "worker"
        environment = "sandbox"
        purpose     = "cks-learning"
      }
    }
  }

  # Security configurations for CKS
  enable_private_cluster = false  # Public for easier access during learning
  enable_irsa           = true   # Required for External Secrets
  enable_cluster_encryption = true

  # CKS Security features
  enable_pod_security_standards = true
  enable_network_policy        = true

  common_tags = local.common_tags

  depends_on = [module.vpc]
}

# Security Module for CKS components
module "security" {
  source = "../../modules/security"

  kubernetes_cluster_id = module.eks_cluster.cluster_id

  # Enable all CKS security features
  enable_opa_gatekeeper   = true
  enable_external_secrets = true
  enable_cert_manager     = true
  enable_falco           = true
  enable_network_policies = true

  # Secure namespaces configuration
  secure_namespaces = {
    portfolio = {
      enforcement_level = "restricted"
      audit_level      = "restricted"
      warn_level       = "restricted"
    }
    monitoring = {
      enforcement_level = "baseline"
      audit_level      = "restricted"
      warn_level       = "restricted"
    }
    security = {
      enforcement_level = "privileged"  # For Falco
      audit_level      = "baseline"
      warn_level       = "baseline"
    }
  }

  depends_on = [module.eks_cluster]
}

# EC2 Instance for Terraform learning
module "ec2_instance" {
  source = "../../modules/ec2-instance"

  project_name = local.project_name
  environment  = local.environment

  # Instance configuration
  instance_type = "t3.micro"  # Free tier eligible
  key_name      = aws_key_pair.main.key_name

  # Network configuration
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.ec2_security_group_id

  # User data for basic setup
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name = local.project_name
    environment  = local.environment
  }))

  common_tags = local.common_tags

  depends_on = [module.vpc]
}

# Key pair for EC2 access
resource "aws_key_pair" "main" {
  key_name   = "${local.project_name}-${local.environment}-key"
  public_key = file("${path.module}/ssh-key.pub")  # Create this file

  tags = local.common_tags
}

# AWS Secrets Manager for External Secrets demonstration
resource "aws_secretsmanager_secret" "portfolio_secrets" {
  name        = "${local.project_name}-${local.environment}-portfolio-secrets"
  description = "Portfolio application secrets for CKS demo"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "portfolio_secrets" {
  secret_id = aws_secretsmanager_secret.portfolio_secrets.id
  secret_string = jsonencode({
    openai_api_key    = "your-openai-api-key-here"
    database_password = "secure-database-password"
    jupyter_token     = "jupyter-access-token"
  })
}