module "aks" {
  source = "../../shared-modules/aks"

  # Basic configuration
  resource_group_name = "linkops-personal-rg"
  location           = "eastus"
  cluster_name       = "linkops-personal-aks"
  node_count         = 2
  dns_prefix         = "linkops-personal"

  # Environment-specific settings
  environment = "personal"
  project     = "linkops"

  # Security configurations for production environment
  # Replace with your actual IP ranges and Azure AD group IDs
  api_server_authorized_ip_ranges = [
    # Example: Add your home/office IP ranges
    # "203.0.113.0/24",  # Office network
    # "198.51.100.14/32" # Home IP
  ]
  enable_azure_rbac      = true
  admin_group_object_ids = [] # Add your Azure AD group object IDs for admin access

  # Full configuration for personal environment
  enable_nginx_ingress = true
  enable_argocd        = true
  enable_monitoring    = true

  # Standard VM size for personal use
  vm_size = "Standard_DS2_v2"

  # Grafana admin password
  grafana_admin_password = var.grafana_admin_password
} 