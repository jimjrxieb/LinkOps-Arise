# Personal environment variables

variable "tf_rg" {
  type        = string
  default     = "linkops-rg"
  description = "Resource group for Terraform state"
}

variable "tf_storage" {
  type        = string
  default     = "linkopsstorage"
  description = "Storage account for Terraform state"
}

variable "tf_container" {
  type        = string
  default     = "tfstate"
  description = "Container for Terraform state"
}

variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana"
  sensitive   = true
} 