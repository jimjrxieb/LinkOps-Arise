output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.aks.resource_group_name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.aks_cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.aks_cluster_fqdn
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.aks.vnet_name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.aks.vnet_id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.aks.aks_subnet_id
} 