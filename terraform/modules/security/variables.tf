# CKS Security Module Variables

variable "kubernetes_cluster_id" {
  description = "ID of the Kubernetes cluster to apply security configurations to"
  type        = string
}

variable "enable_opa_gatekeeper" {
  description = "Enable OPA Gatekeeper for policy enforcement"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for TLS certificate management"
  type        = bool
  default     = true
}

variable "enable_falco" {
  description = "Enable Falco for runtime security monitoring"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable default deny network policies"
  type        = bool
  default     = true
}

variable "secure_namespaces" {
  description = "Namespaces to configure with Pod Security Standards"
  type = map(object({
    enforcement_level = string
    audit_level      = string
    warn_level       = string
  }))
  default = {
    portfolio = {
      enforcement_level = "restricted"
      audit_level      = "restricted"
      warn_level       = "restricted"
    }
    monitoring = {
      enforcement_level = "baseline"
      audit_level      = "restricted"
      warn_level       = "restricted"
    }
    ingress-nginx = {
      enforcement_level = "baseline"
      audit_level      = "baseline"
      warn_level       = "baseline"
    }
  }
}

variable "falco_rules_config" {
  description = "Custom Falco rules configuration"
  type        = map(string)
  default     = {}
}

variable "gatekeeper_policy_config" {
  description = "OPA Gatekeeper policy configuration"
  type = object({
    enable_mutations     = bool
    enable_external_data = bool
    violation_enforcement = string
  })
  default = {
    enable_mutations     = true
    enable_external_data = true
    violation_enforcement = "warn"  # Can be "warn" or "deny"
  }
}