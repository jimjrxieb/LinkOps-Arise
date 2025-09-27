# CKS Security Module - OPA Gatekeeper, Pod Security Standards, Network Policies

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# OPA Gatekeeper installation
resource "helm_release" "gatekeeper" {
  count = var.enable_opa_gatekeeper ? 1 : 0

  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  version    = "3.14.0"
  namespace  = "gatekeeper-system"

  create_namespace = true

  values = [
    yamlencode({
      replicas = 2
      resources = {
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
      }
      # CKS Security: Enable mutations and external data
      enableExternalData = true
      mutations = {
        enable = true
      }
      # Security contexts for Gatekeeper pods
      podSecurityContext = {
        runAsNonRoot = true
        runAsUser    = 65532
        runAsGroup   = 65532
        fsGroup      = 65532
      }
      securityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        runAsNonRoot             = true
        runAsUser                = 65532
        runAsGroup               = 65532
        capabilities = {
          drop = ["ALL"]
        }
      }
    })
  ]

  depends_on = [var.kubernetes_cluster_id]
}

# External Secrets Operator
resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.11"
  namespace  = "external-secrets-system"

  create_namespace = true

  values = [
    yamlencode({
      installCRDs = true
      resources = {
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
      }
      # CKS Security: Secure configuration
      securityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        runAsNonRoot             = true
        runAsUser                = 65532
        capabilities = {
          drop = ["ALL"]
        }
      }
      podSecurityContext = {
        runAsNonRoot = true
        runAsUser    = 65532
        fsGroup      = 65532
      }
    })
  ]

  depends_on = [var.kubernetes_cluster_id]
}

# cert-manager for TLS certificate management
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.2"
  namespace  = "cert-manager"

  create_namespace = true

  values = [
    yamlencode({
      installCRDs = true
      global = {
        rbac = {
          create = true
        }
      }
      # CKS Security: Secure configuration
      securityContext = {
        runAsNonRoot = true
      }
      resources = {
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
      }
    })
  ]

  depends_on = [var.kubernetes_cluster_id]
}

# Falco for runtime security monitoring
resource "helm_release" "falco" {
  count = var.enable_falco ? 1 : 0

  name       = "falco"
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = "3.8.4"
  namespace  = "falco-system"

  create_namespace = true

  values = [
    yamlencode({
      # CKS Security: Falco configuration for runtime security
      falco = {
        rules_file = [
          "/etc/falco/falco_rules.yaml",
          "/etc/falco/falco_rules.local.yaml",
          "/etc/falco/k8s_audit_rules.yaml",
          "/etc/falco/rules.d"
        ]
        # Custom rules for CKS scenarios
        customRules = {
          "custom-rules.yaml" = <<-EOF
            - rule: Kubernetes Privilege Escalation
              desc: Detect privilege escalation attempts
              condition: >
                k8s_audit and ka.verb=create and ka.obj_name contains "privileged"
              output: Privilege escalation attempt (user=%ka.user.name verb=%ka.verb obj=%ka.obj_name)
              priority: WARNING
              tags: [k8s, security, privilege-escalation]

            - rule: Suspicious Network Activity
              desc: Detect suspicious network connections
              condition: >
                spawned_process and proc.name=nc
              output: Netcat usage detected (user=%user.name command=%proc.cmdline)
              priority: WARNING
              tags: [network, security]

            - rule: Write to Sensitive Directory
              desc: Detect writes to sensitive directories
              condition: >
                open_write and (fd.name startswith /etc or fd.name startswith /boot)
              output: Write to sensitive directory (file=%fd.name command=%proc.cmdline)
              priority: ERROR
              tags: [filesystem, security]
          EOF
        }
      }
      driver = {
        enabled = true
        kind    = "ebpf"
      }
      collectors = {
        enabled           = true
        docker = {
          enabled = false
        }
        containerd = {
          enabled = true
          socket  = "/run/containerd/containerd.sock"
        }
        kubernetes = {
          enabled = true
        }
      }
      # Resource limits
      resources = {
        limits = {
          cpu    = "200m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
      }
      # Security context
      securityContext = {
        privileged = true  # Required for eBPF
      }
    })
  ]

  depends_on = [var.kubernetes_cluster_id]
}

# Network Policy enforcement (Calico or Azure Network Policy)
resource "kubectl_manifest" "default_deny_ingress" {
  count = var.enable_network_policies ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "default-deny-ingress"
      namespace = "default"
      labels = {
        "app.kubernetes.io/name"       = "network-policy"
        "app.kubernetes.io/component"  = "security"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress"]
      # Empty ingress rules = deny all ingress traffic
    }
  })

  depends_on = [var.kubernetes_cluster_id]
}

resource "kubectl_manifest" "default_deny_egress" {
  count = var.enable_network_policies ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "default-deny-egress"
      namespace = "default"
      labels = {
        "app.kubernetes.io/name"       = "network-policy"
        "app.kubernetes.io/component"  = "security"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      podSelector = {}
      policyTypes = ["Egress"]
      # Empty egress rules = deny all egress traffic
    }
  })

  depends_on = [var.kubernetes_cluster_id]
}

# Pod Security Standards namespace configuration
resource "kubernetes_namespace" "secure_namespaces" {
  for_each = var.secure_namespaces

  metadata {
    name = each.key
    labels = {
      # Pod Security Standards enforcement
      "pod-security.kubernetes.io/enforce" = each.value.enforcement_level
      "pod-security.kubernetes.io/audit"   = each.value.audit_level
      "pod-security.kubernetes.io/warn"    = each.value.warn_level
      # Standard labels
      "app.kubernetes.io/managed-by" = "terraform"
      # Network isolation
      "networking/namespace" = each.key
    }
  }

  depends_on = [var.kubernetes_cluster_id]
}