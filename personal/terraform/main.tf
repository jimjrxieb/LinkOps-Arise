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
  # SECURITY FIX: Configure specific authorized IP ranges for personal environment
  api_server_authorized_ip_ranges = [
    "98.242.160.0/24",    # Current development network range
    "10.0.0.0/16",        # Private network range (more restrictive than /8)
    "172.16.0.0/16",      # Private network range (more restrictive than /12)
    "192.168.0.0/24"      # Local network range (more restrictive than /16)
  ] # PRODUCTION-READY: Restrictive IP ranges for enhanced security
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