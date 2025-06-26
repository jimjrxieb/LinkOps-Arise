terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  
  backend "azurerm" {
    # Configure your Azure storage account for state
    # resource_group_name  = "linkops-terraform-rg"
    # storage_account_name = "linkopsterraform"
    # container_name       = "tfstate"
    # key                  = "linkops.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-linkops-demo"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-linkops"
}

variable "node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "linkops"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "linkopsacr"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
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

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
  
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "linkops"
  kubernetes_version  = "1.28.0"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    vnet_subnet_id      = azurerm_subnet.aks.id
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
    docker_bridge_cidr = "172.17.0.1/16"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [azurerm_container_registry.main]
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

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.main.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.main.admin_password
  sensitive = true
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# Helm Provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

# ArgoCD Helm Chart
module "argocd" {
  source  = "terraform-helm/argocd/kubernetes"
  version = ">= 1.0"

  namespace = "argocd"
  create_namespace = true
  chart  = "argo-cd"
  repo   = "https://argoproj.github.io/argo-helm"
  
  values = [
    <<-EOT
    server:
      extraArgs:
        - --insecure
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: nginx
        hosts:
          - argocd.linkops.local
    configs:
      secret:
        argocdServerAdminPassword: "$2a$10$rQZ8iKcJqX8qX8qX8qX8qO"
    EOT
  ]
}

# Prometheus Stack Helm Chart
module "kube_prometheus_stack" {
  source  = "terraform-helm/kube-prometheus-stack/kubernetes"
  version = ">= 1.0"

  namespace = "monitoring"
  create_namespace = true
  chart  = "kube-prometheus-stack"
  repo   = "https://prometheus-community.github.io/helm-charts"
  
  values = [
    <<-EOT
    grafana:
      adminPassword: "${var.grafana_admin_password}"
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: nginx
        hosts:
          - grafana.linkops.local
    prometheus:
      prometheusSpec:
        retention: 7d
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: managed-premium
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi
    EOT
  ]
}

# Loki Stack Helm Chart
module "loki" {
  source  = "terraform-helm/loki-stack/kubernetes"
  version = ">= 1.0"

  namespace = "logging"
  create_namespace = true
  chart  = "loki-stack"
  repo   = "https://grafana.github.io/helm-charts"
  
  values = [
    <<-EOT
    loki:
      persistence:
        enabled: true
        storageClassName: managed-premium
        size: 10Gi
    grafana:
      enabled: false  # We already have Grafana from prometheus stack
    promtail:
      enabled: true
    EOT
  ]
}

# Vault Helm Chart (Optional)
module "vault" {
  source  = "terraform-helm/vault/kubernetes"
  version = ">= 1.0"

  namespace = "vault"
  create_namespace = true
  chart  = "vault"
  repo   = "https://helm.releases.hashicorp.com"
  
  values = [
    <<-EOT
    server:
      dev:
        enabled: true
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: nginx
        hosts:
          - vault.linkops.local
    EOT
  ]
}

# ArgoCD Application for LinkOps
resource "kubernetes_manifest" "argocd_app" {
  depends_on = [module.argocd]
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "linkops-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/yourusername/linkops.git"
        targetRevision = "main"
        path          = "infrastructure/k8s/app"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "linkops"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
} 