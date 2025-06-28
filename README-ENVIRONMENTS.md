# LinkOps-Arise Environment Structure

This repository has been restructured to support multiple environments with shared Terraform modules.

## Directory Structure

```
LinkOps-Arise/
├── demo/
│   └── terraform/           # Demo environment (minimal configuration)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── backend.tf
│       └── terraform.tfvars
├── personal/
│   └── terraform/           # Personal environment (full configuration)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── backend.tf
│       └── terraform.tfvars
├── shared-modules/
│   └── aks/                 # Shared AKS module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── argocd-values.yaml
│       └── monitoring-values.yaml
├── scripts/                 # Kubernetes manifests and utilities
│   ├── argocd-values.yaml
│   ├── cleanup-secrets.sh
│   ├── import_aks.sh
│   └── monitoring-values.yaml
├── infra-scripts/           # Infrastructure management scripts
│   ├── az-install.sh
│   ├── manage-environments.sh
│   ├── monitoring-setup.sh
│   ├── register_tsi_provider.sh
│   └── setup-secrets.sh
├── README.md                # Main project documentation
├── README-ENVIRONMENTS.md   # This file
└── MIGRATION-SUMMARY.md     # Migration documentation
```

## Environment Differences

### Demo Environment (`demo/terraform/`)
- **Purpose**: Cost-effective demo/testing environment
- **Configuration**:
  - 1 worker node
  - Smaller VM size (`Standard_B2s`)
  - No additional addons (NGINX, ArgoCD, Monitoring)
  - Resource group: `linkops-demo-rg`
  - Cluster name: `linkops-demo-aks`

### Personal Environment (`personal/terraform/`)
- **Purpose**: Full-featured personal development environment
- **Configuration**:
  - 2 worker nodes
  - Standard VM size (`Standard_DS2_v2`)
  - All addons enabled (NGINX, ArgoCD, Monitoring)
  - Resource group: `linkops-personal-rg`
  - Cluster name: `linkops-personal-aks`

## Usage

### Using the Management Script (Recommended)
```bash
# From the repository root
./infra-scripts/manage-environments.sh demo init
./infra-scripts/manage-environments.sh demo plan
./infra-scripts/manage-environments.sh demo apply

./infra-scripts/manage-environments.sh personal init
./infra-scripts/manage-environments.sh personal plan
./infra-scripts/manage-environments.sh personal apply
```

### Manual Deployment
```bash
# Deploy demo environment
cd demo/terraform
terraform init
terraform plan
terraform apply

# Deploy personal environment
cd personal/terraform
terraform init
terraform plan
terraform apply
```

### Destroy Environment
```bash
# Using management script
./infra-scripts/manage-environments.sh demo destroy
./infra-scripts/manage-environments.sh personal destroy

# Manual
cd <environment>/terraform
terraform destroy
```

## Terraform State Management

Each environment has its own Terraform state file:
- Demo: `demo.terraform.tfstate`
- Personal: `personal.terraform.tfstate`

This allows independent management of each environment without conflicts.

## Shared Module Features

The shared AKS module (`shared-modules/aks/`) supports:

### Optional Features (controlled by variables)
- **NGINX Ingress Controller**: `enable_nginx_ingress`
- **ArgoCD GitOps**: `enable_argocd`
- **Prometheus Monitoring**: `enable_monitoring`

### Configuration Options
- Kubernetes version
- VM sizes
- Node counts
- Network configuration
- Log retention settings

## CI/CD Integration

For GitHub Actions, you can create separate workflows or jobs:

```yaml
jobs:
  demo:
    working-directory: demo/terraform
    steps:
      - uses: actions/checkout@v3
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan
      - name: Terraform Apply
        run: terraform apply -auto-approve

  personal:
    working-directory: personal/terraform
    steps:
      - uses: actions/checkout@v3
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## Infrastructure Scripts

The `infra-scripts/` directory contains useful utilities:

- **`manage-environments.sh`**: Main environment management script
- **`az-install.sh`**: Azure CLI installation helper
- **`monitoring-setup.sh`**: Prometheus/Grafana setup
- **`register_tsi_provider.sh`**: Azure provider registration
- **`setup-secrets.sh`**: Kubernetes secrets management

## Benefits of This Structure

1. **Environment Isolation**: Each environment has its own state and configuration
2. **Code Reuse**: Shared modules reduce duplication
3. **Cost Control**: Demo environment uses minimal resources
4. **Flexibility**: Easy to add new environments or modify existing ones
5. **Maintainability**: Clear separation of concerns
6. **Clean Organization**: Infrastructure scripts separated from application scripts 