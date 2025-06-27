# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "linkops-rg"
  location = "eastus"

  lifecycle {
    prevent_destroy = true
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "linkops-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  provider            = azurerm.aks
  name                = "linkops-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "linkops"
  kubernetes_version  = "1.30.12"
  sku_tier            = "Premium"
  support_plan        = "AKSLongTermSupport"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = "10.0.2.0/24"
    dns_service_ip     = "10.0.2.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = {
    environment = "linkops"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "system" {
  name                  = "systemnp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 1
  mode                  = "System"
}

# Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "linkops-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# NGINX Ingress Controller
# Temporarily commented out until AKS cluster is created
# resource "helm_release" "nginx_ingress" {
#   name       = "nginx-ingress"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"
#   create_namespace = true

#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "controller.ingressClassResource.name"
#     value = "nginx"
#   }

#   set {
#     name  = "controller.ingressClassResource.default"
#     value = "true"
#   }

#   depends_on = [azurerm_kubernetes_cluster.main]
# }

# Optional: install ArgoCD via Helm
# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   namespace  = "argocd"
#   create_namespace = true
#   version    = "5.51.6"

#   values = [
#     file("${path.module}/scripts/argocd-values.yaml")
#   ]
# }

# resource "helm_release" "kube_prometheus_stack" {
#   name             = "kube-prometheus"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-prometheus-stack"
#   namespace        = "monitoring"
#   create_namespace = true
#   version          = "55.5.0"

#   values = [
#     file("${path.module}/scripts/monitoring-values.yaml")
#   ]
# } 