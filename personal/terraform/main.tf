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
  
  # Full configuration for personal environment
  enable_nginx_ingress = true
  enable_argocd        = true
  enable_monitoring    = true
  
  # Standard VM size for personal use
  vm_size = "Standard_DS2_v2"
  
  # Grafana admin password
  grafana_admin_password = var.grafana_admin_password
} 