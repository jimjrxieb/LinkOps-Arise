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
  skip_provider_registration = true
}

provider "azurerm" {
  features {}
  subscription_id = "e864a989-7282-4f8e-8ded-2b68911dcc95"
  skip_provider_registration = true
  alias  = "aks"
} 