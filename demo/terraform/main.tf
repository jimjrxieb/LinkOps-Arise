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
  
  # Optional features disabled for demo
  enable_nginx_ingress = false
  enable_argocd        = false
  enable_monitoring    = false
} 