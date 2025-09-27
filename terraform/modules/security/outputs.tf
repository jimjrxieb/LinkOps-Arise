# CKS Security Module Outputs

output "gatekeeper_namespace" {
  description = "Namespace where OPA Gatekeeper is installed"
  value       = var.enable_opa_gatekeeper ? "gatekeeper-system" : null
}

output "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  value       = var.enable_external_secrets ? "external-secrets-system" : null
}

output "cert_manager_namespace" {
  description = "Namespace where cert-manager is installed"
  value       = var.enable_cert_manager ? "cert-manager" : null
}

output "falco_namespace" {
  description = "Namespace where Falco is installed"
  value       = var.enable_falco ? "falco-system" : null
}

output "secure_namespaces" {
  description = "Namespaces configured with Pod Security Standards"
  value       = var.secure_namespaces
}

output "security_features_enabled" {
  description = "Summary of enabled security features"
  value = {
    opa_gatekeeper    = var.enable_opa_gatekeeper
    external_secrets  = var.enable_external_secrets
    cert_manager      = var.enable_cert_manager
    falco            = var.enable_falco
    network_policies = var.enable_network_policies
  }
}