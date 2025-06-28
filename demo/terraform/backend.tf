terraform {
  backend "azurerm" {
    resource_group_name  = "linkops-rg"
    storage_account_name = "linkopsstorage"
    container_name       = "tfstate"
    key                  = "demo.terraform.tfstate"
    use_oidc             = true
  }
} 