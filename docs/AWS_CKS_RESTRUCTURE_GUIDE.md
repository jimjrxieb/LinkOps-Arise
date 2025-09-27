# LinkOps-Arise AWS CKS Restructure Guide

## Overview

Successfully restructured the LinkOps-Arise project from Azure-focused to AWS-focused architecture for CKS (Certified Kubernetes Security Specialist) preparation. This change provides better learning resources, clearer documentation, and simplified cloud architecture patterns.

## New Directory Structure

```
LinkOps-Arise/
├── terraform/
│   ├── environments/
│   │   ├── sandbox/          # AWS EKS learning environment
│   │   │   ├── main.tf       # Complete sandbox infrastructure
│   │   │   ├── user-data.sh  # EC2 setup script
│   │   │   └── outputs.tf
│   │   └── local/            # Docker Desktop K8s (future)
│   ├── modules/
│   │   ├── aws-vpc/          # Reusable VPC module
│   │   ├── eks-cluster/      # EKS cluster module (to be created)
│   │   ├── ec2-instance/     # EC2 learning module (to be created)
│   │   ├── monitoring/       # ArgoCD+Grafana+Prometheus
│   │   └── security/         # OPA Gatekeeper, Falco, External Secrets
│   └── shared/
│       ├── variables.tf      # Common variables
│       └── versions.tf       # Provider configurations
├── opa-policies/             # CKS policy examples
│   ├── security/
│   ├── compliance/
│   └── governance/
├── applications/
│   └── portfolio/            # Secure K8s manifests
└── k8s-manifests/portfolio/  # Updated with security contexts
```

## Day 0 Completed: Critical Security Fixes ✅

### 1. Secrets Management
- **Fixed**: Removed hardcoded base64 secrets from `k8s-manifests/portfolio/secret.yaml`
- **Implemented**: External Secrets Operator template with AWS Secrets Manager integration
- **Added**: Proper annotations for external secret management

### 2. CORS Security
- **Fixed**: Changed `cors-allow-origin: "*"` to specific domains in `ingress.yaml`
- **Added**: Security headers (X-Frame-Options, HSTS, X-Content-Type-Options)
- **Enabled**: TLS enforcement with cert-manager integration

### 3. Container Security Contexts
- **Fixed**: Added comprehensive security contexts to all deployment manifests
- **Implemented**: Non-root user execution (UID 1001)
- **Added**: ReadOnlyRootFilesystem, dropped all capabilities
- **Created**: Script `scripts/apply-security-contexts.sh` for bulk updates

### 4. TLS Configuration
- **Added**: cert-manager configuration with Let's Encrypt and self-signed issuers
- **Implemented**: TLS termination at ingress level
- **Created**: Certificate management automation

## Day 1-2 In Progress: AWS Infrastructure Consolidation 🚧

### Terraform Modularization

#### 1. Shared Configuration (`terraform/shared/`)
- **Variables**: Comprehensive CKS-focused configuration options
- **Providers**: AWS, Kubernetes, Helm, kubectl with proper versioning
- **Features**: Support for EKS, EC2, security tools, monitoring

#### 2. VPC Module (`terraform/modules/aws-vpc/`)
- **Complete VPC setup**: Public/private subnets across 3 AZs
- **Security Groups**: Pre-configured for EKS control plane, nodes, and EC2
- **Cost Optimization**: Optional NAT gateways (disabled in sandbox)
- **Kubernetes Integration**: Proper subnet tagging for load balancers

#### 3. Security Module (`terraform/modules/security/`)
- **OPA Gatekeeper**: Policy enforcement with custom CKS rules
- **External Secrets**: AWS Secrets Manager integration
- **cert-manager**: Automated TLS certificate management
- **Falco**: Runtime security monitoring with custom rules
- **Network Policies**: Default deny rules for micro-segmentation

#### 4. Sandbox Environment (`terraform/environments/sandbox/`)
- **Complete EKS Setup**: Cost-optimized cluster with spot instances
- **EC2 Learning Instance**: Pre-configured with all CKS tools
- **Security Demonstrations**: All security tools enabled
- **AWS Secrets Manager**: Example secret configuration

### Key AWS Advantages Realized

1. **Better Documentation**: Extensive AWS Terraform examples available
2. **Cost Efficiency**: t3.micro (free tier), spot instances, optional NAT gateways
3. **Learning Focus**: EKS patterns widely documented, clearer than AKS
4. **Tool Ecosystem**: Better integration with kubectl, helm, k9s

## CKS Security Features Implemented

### 1. Pod Security Standards ✅
```yaml
# Namespace labels for PSS enforcement
labels:
  pod-security.kubernetes.io/enforce: restricted
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/warn: restricted
```

### 2. Container Security Contexts ✅
```yaml
# Applied to all portfolio services
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

### 3. Network Security ✅
- TLS enforcement with security headers
- Restricted CORS origins
- Security groups with least privilege
- Network policy templates ready

### 4. Secrets Management ✅
- External Secrets Operator configuration
- AWS Secrets Manager integration
- Eliminated hardcoded secrets

## Next Steps Roadmap

### Day 3-4: OPA Gatekeeper Policies
- [ ] Create comprehensive constraint templates
- [ ] Implement security policies for CKS domains
- [ ] Add mutation policies for automatic security enforcement

### Day 5-6: Network Policies & RBAC
- [ ] Implement micro-segmentation with NetworkPolicies
- [ ] Create least-privilege RBAC configurations
- [ ] Add service account security

### Day 7: Falco Runtime Security
- [ ] Deploy Falco with custom CKS rules
- [ ] Configure runtime security monitoring
- [ ] Implement security alerting

## Learning Benefits

### 1. Terraform Skills Transfer
- Resource block patterns identical across clouds
- State management concepts universal
- Module patterns reusable
- Dependency management same principles

### 2. CKS Preparation
- All security tools cloud-agnostic
- Kubernetes security concepts universal
- Policy enforcement patterns transferable
- Runtime security monitoring consistent

### 3. Interview Readiness
- Demonstrates infrastructure-as-code expertise
- Shows security-first thinking
- Proves modular architecture design
- Exhibits cost optimization awareness

## Cost Optimization Features

1. **Spot Instances**: 70% cost reduction for worker nodes
2. **No NAT Gateways**: $45/month savings in sandbox
3. **t3.micro EC2**: Free tier eligible
4. **Resource Limits**: Prevents cost overruns
5. **Auto-scaling**: Scales to zero when not used

## Deployment Instructions

### Prerequisites
```bash
# Install required tools
aws configure
terraform --version  # >= 1.5.0
kubectl version
```

### Deploy Sandbox Environment
```bash
cd terraform/environments/sandbox

# Create SSH key pair
ssh-keygen -t rsa -b 4096 -f ssh-key
# Copy ssh-key.pub content to file

# Initialize and deploy
terraform init
terraform plan
terraform apply

# Connect to EKS cluster
aws eks update-kubeconfig --region us-east-1 --name linkops-arise-sandbox-eks

# Verify deployment
kubectl cluster-info
kubectl get nodes
```

### Access Learning Environment
```bash
# SSH to EC2 instance
ssh -i ssh-key ec2-user@<ec2-public-ip>

# Use k9s for cluster management
k9s

# Practice CKS scenarios
cd ~/cks-practice
```

## Security Validation Checklist

- [x] No hardcoded secrets in source code
- [x] All containers run as non-root
- [x] ReadOnlyRootFilesystem enabled
- [x] TLS encryption enforced
- [x] CORS properly restricted
- [x] Security headers implemented
- [x] External secrets management configured
- [x] Pod Security Standards enforced
- [ ] Network policies implemented (Day 5-6)
- [ ] OPA policies active (Day 3-4)
- [ ] Falco monitoring active (Day 7)

## Conclusion

The AWS restructure successfully transforms the LinkOps-Arise project into a focused CKS learning platform while maintaining production-ready security practices. The modular Terraform architecture provides clear learning paths for both infrastructure-as-code and Kubernetes security concepts.

The security-first approach demonstrates industry best practices while the cost optimization features make it suitable for extended learning and practice sessions.

Next phase focuses on policy enforcement and runtime security to complete the CKS preparation framework.