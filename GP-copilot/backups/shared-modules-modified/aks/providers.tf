terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "azurerm" {
  features {}
  subscription_id = "e864a989-7282-4f8e-8ded-2b68911dcc95"
  resource_provider_registrations = "none"
}

provider "azurerm" {
  features {}
  subscription_id = "e864a989-7282-4f8e-8ded-2b68911dcc95"
  resource_provider_registrations = "none"
  alias  = "aks"
}

# Temporarily commented out until AKS cluster is created
# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
# }

# provider "helm" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
#     client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
#     client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
#   }
# } 