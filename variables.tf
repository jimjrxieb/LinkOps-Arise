variable "resource_group_name" {
  type        = string
  default     = "linkops-rg"
  description = "Azure Resource Group name"
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Azure region"
}

variable "cluster_name" {
  type        = string
  default     = "linkops-aks"
  description = "AKS cluster name"
}

variable "node_count" {
  type        = number
  default     = 2
  description = "Number of AKS worker nodes"
}

variable "dns_prefix" {
  type        = string
  default     = "linkops"
  description = "DNS prefix for AKS"
}

variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana"
  sensitive   = true
} 