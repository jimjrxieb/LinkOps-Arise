# Demo environment variables
# Most configuration is handled in main.tf for simplicity

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