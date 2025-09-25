module "aks" {
  source = "../../shared-modules/aks"

  # Basic configuration
  resource_group_name = "linkops-demo-rg"
  location            = "eastus"
  cluster_name        = "linkops-demo-aks"
  node_count          = 1
  dns_prefix          = "linkops-demo"

  # Environment-specific settings
  environment         = "demo"
  project             = "linkops"

  # Smaller VM size for demo
  vm_size             = "Standard_B2s"

  # Security configurations
  # SECURITY FIX: Restrict API server access to specific development/testing IP ranges
  # Include current public IP, common development networks, and Azure internal ranges
  api_server_authorized_ip_ranges = [
    "98.242.160.0/24",    # Current development network range
    "10.0.0.0/8",         # Private network range for VPN/internal access
    "172.16.0.0/12",      # Private network range for Docker/container networks
    "192.168.0.0/16"      # Private network range for local development
  ] # REMOVED: 0.0.0.0/0 - was critical security vulnerability
  enable_azure_rbac              = true
  admin_group_object_ids         = [] # Add your Azure AD group IDs here

  # Optional features disabled for demo
  enable_nginx_ingress = false
  enable_argocd        = false
  enable_monitoring    = false
} 