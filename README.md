# LinkOps Terraform Infrastructure

This directory contains the Terraform configuration for deploying the LinkOps infrastructure on Azure Kubernetes Service (AKS) with Azure Container Registry (ACR).

## Architecture

- **Azure Resource Group**: `linkops-rg`
- **Azure Kubernetes Service**: `linkops-aks` with auto-scaling (1-3 nodes)
- **Azure Container Registry**: `linkopsacr` for storing container images
- **Virtual Network**: Custom VNet with dedicated subnet for AKS
- **Log Analytics**: For AKS monitoring and logging
- **NGINX Ingress Controller**: For external traffic routing

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.0 installed
3. **kubectl** installed
4. **helm** installed

## Quick Start

### 1. Authenticate with Azure

```bash
az login
az account set --subscription <your-subscription-id>
```

### 2. Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

### 5. Configure kubectl

```bash
# Get the kubeconfig
az aks get-credentials --resource-group linkops-rg --name linkops-aks

# Verify connection
kubectl cluster-info
```

## Configuration

### Variables

Key variables can be customized in `variables.tf`:

- `resource_group_name`: Resource group name (default: "linkops-rg")
- `location`: Azure region (default: "East US")
- `cluster_name`: AKS cluster name (default: "linkops-aks")
- `node_count`: Number of AKS nodes (default: 2)
- `vm_size`: VM size for AKS nodes (default: "Standard_DS2_v2")
- `acr_name`: ACR name (default: "linkopsacr")

### Customization

To customize the deployment:

1. Create a `terraform.tfvars` file:
```hcl
resource_group_name = "my-linkops-rg"
location           = "West US 2"
cluster_name       = "my-linkops-aks"
node_count         = 3
vm_size            = "Standard_DS3_v2"
acr_name           = "mylinkopsacr"
```

2. Apply with custom values:
```bash
terraform apply -var-file="terraform.tfvars"
```

## Outputs

After successful deployment, Terraform will output:

- `resource_group_name`: Name of the created resource group
- `aks_cluster_name`: Name of the AKS cluster
- `aks_cluster_id`: ID of the AKS cluster
- `aks_kube_config`: Kubeconfig for cluster access (sensitive)
- `acr_login_server`: ACR login server URL
- `acr_admin_username`: ACR admin username
- `acr_admin_password`: ACR admin password (sensitive)
- `vnet_name`: Virtual network name
- `vnet_id`: Virtual network ID
- `aks_subnet_id`: AKS subnet ID

## Remote State Storage (Optional)

For production deployments, configure remote state storage:

1. Create a storage account in Azure
2. Create a container named "tfstate"
3. Uncomment and configure `backend.tf`
4. Run: `terraform init -reconfigure`

## Security Features

- **System-assigned managed identity** for AKS
- **Azure CNI** networking with network policies
- **ACR integration** with proper role assignments
- **Auto-scaling** enabled (1-3 nodes)
- **Log Analytics** integration for monitoring

## Cost Optimization

- **Basic ACR SKU** for cost-effective container registry
- **Auto-scaling** to minimize idle resources
- **Standard_DS2_v2** VM size for good performance/cost ratio

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

⚠️ **Warning**: This will delete all resources including the AKS cluster and ACR.

## Troubleshooting

### Common Issues

1. **ACR Name Conflict**: ACR names must be globally unique. Change `acr_name` if needed.
2. **VM Size Not Available**: Some VM sizes may not be available in all regions.
3. **Resource Group Already Exists**: Ensure the resource group name is unique.

### Useful Commands

```bash
# Check AKS status
az aks show --resource-group linkops-rg --name linkops-aks

# Get ACR credentials
az acr credential show --name linkopsacr

# Check node status
kubectl get nodes

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## Next Steps

After infrastructure deployment:

1. Build and push your microservices to ACR
2. Deploy applications using the provided Kubernetes manifests
3. Configure ingress rules for external access
4. Set up monitoring and alerting

## Support

For issues or questions:
- Check Azure documentation for AKS and ACR
- Review Terraform Azure provider documentation
- Check the LinkOps project documentation 