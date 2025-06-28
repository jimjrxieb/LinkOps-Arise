variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "node_count" {
  type        = number
  description = "Number of AKS worker nodes"
}

variable "system_node_count" {
  type        = number
  default     = 1
  description = "Number of system nodes"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for AKS"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.30.12"
  description = "Kubernetes version"
}

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "VM size for AKS nodes"
}

variable "sku_tier" {
  type        = string
  default     = "Premium"
  description = "SKU tier for AKS cluster"
}

variable "support_plan" {
  type        = string
  default     = "AKSLongTermSupport"
  description = "Support plan for AKS cluster"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Log retention days for Log Analytics"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

# Optional features
variable "enable_nginx_ingress" {
  type        = bool
  default     = false
  description = "Enable NGINX Ingress Controller"
}

variable "enable_argocd" {
  type        = bool
  default     = false
  description = "Enable ArgoCD"
}

variable "enable_monitoring" {
  type        = bool
  default     = false
  description = "Enable Prometheus monitoring stack"
}

variable "argocd_version" {
  type        = string
  default     = "5.51.6"
  description = "ArgoCD Helm chart version"
}

variable "prometheus_version" {
  type        = string
  default     = "55.5.0"
  description = "Prometheus stack Helm chart version"
}

variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana"
  sensitive   = true
  default     = null
} 