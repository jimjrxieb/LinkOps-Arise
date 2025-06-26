# Uncomment and configure for remote state storage
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "linkops-terraform-rg"
#     storage_account_name = "linkopsterraform"
#     container_name       = "tfstate"
#     key                  = "linkops.terraform.tfstate"
#   }
# }

# To use remote state storage:
# 1. Create a storage account in Azure
# 2. Create a container named "tfstate"
# 3. Uncomment the above configuration
# 4. Update the resource_group_name and storage_account_name
# 5. Run: terraform init -reconfigure 