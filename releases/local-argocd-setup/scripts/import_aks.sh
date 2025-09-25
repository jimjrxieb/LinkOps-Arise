#!/bin/bash
# Rune: Import existing AKS cluster and deploy
# Usage: ./import_aks.sh
# Store in LinkOps-Arise/scripts/import_aks.sh

# Variables (adjust based on LinkOps-Arise setup)
SUBSCRIPTION_ID="e864a989-7282-4f8e-8ded-2b68911dcc95"
RESOURCE_GROUP="linkops-rg"
CLUSTER_NAME="linkops-aks"
AKS_RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME"
TF_STATE_PATH="tfstate/linkops.tfstate"
AZURE_STORAGE_ACCOUNT="linkopsstorage"
AZURE_CONTAINER="tfstate"
LOG_FILE="aks_import.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Output helpers
print_status()   { echo -e "${BLUE}[INFO]${NC} $1" | tee -a $LOG_FILE; }
print_success()  { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $LOG_FILE; }
print_warning()  { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE; }
print_error()    { echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE; }

echo "Starting AKS import and deployment..." | tee -a $LOG_FILE

# Check for active Terraform processes
print_status "Checking for active Terraform processes..."
if ps aux | grep -v grep | grep terraform >/dev/null; then
  print_error "Active Terraform process found. Terminate it before continuing."
  exit 1
fi

# Verify Azure storage account and container
print_status "Verifying storage account and container..."
az storage account show --name "$AZURE_STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  print_error "Storage account $AZURE_STORAGE_ACCOUNT not found in $RESOURCE_GROUP."
  exit 1
fi

az storage container show --name "$AZURE_CONTAINER" --account-name "$AZURE_STORAGE_ACCOUNT" >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  print_error "Container $AZURE_CONTAINER not found in $AZURE_STORAGE_ACCOUNT."
  exit 1
fi

# Verify AKS cluster exists
print_status "Verifying AKS cluster $CLUSTER_NAME exists..."
az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  print_success "AKS cluster $CLUSTER_NAME found in $RESOURCE_GROUP."
  
  # Get cluster properties for alignment
  print_status "Retrieving cluster properties for configuration alignment..."
  CLUSTER_PROPERTIES=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "{version:kubernetesVersion, nodeCount:defaultNodePool.count, networkPlugin:networkProfile.networkPlugin, serviceCidr:networkProfile.serviceCidr, dnsServiceIp:networkProfile.dnsServiceIp, location:location}" -o json)
  echo "Cluster properties: $CLUSTER_PROPERTIES" >> $LOG_FILE
  print_status "Cluster properties retrieved. Check $LOG_FILE for details."
else
  print_error "AKS cluster $CLUSTER_NAME not found. Check Azure Portal or CLI."
  exit 1
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  print_error "Terraform init failed. Check backend config and credentials."
  exit 1
fi

# Import AKS cluster into Terraform state
print_status "Importing AKS cluster $CLUSTER_NAME into Terraform state..."
terraform import azurerm_kubernetes_cluster.main "$AKS_RESOURCE_ID" >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  print_success "AKS cluster imported successfully."
else
  print_error "Failed to import AKS cluster. Check $LOG_FILE for details."
  exit 1
fi

# Verify the import
print_status "Verifying Terraform state..."
terraform state list | grep azurerm_kubernetes_cluster.main >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  print_success "AKS cluster found in Terraform state."
else
  print_error "AKS cluster not found in Terraform state after import."
  exit 1
fi

# Validate Terraform plan
print_status "Generating Terraform plan to check for configuration drift..."
terraform plan -lock-timeout=30s -out=tfplan >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  print_success "Terraform plan generated successfully. Review $LOG_FILE for any changes."
else
  print_error "Terraform plan failed. Check $LOG_FILE for details and align main.tf with existing cluster."
  exit 1
fi

# Apply Terraform plan
print_status "Applying Terraform configuration..."
terraform apply tfplan >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  print_success "AKS configuration applied successfully! Outputs in $LOG_FILE."
  
  # Retrieve kubeconfig
  print_status "Retrieving kubeconfig..."
  az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" >> $LOG_FILE 2>&1
  if [ $? -eq 0 ]; then
    print_success "Kubeconfig retrieved successfully."
    
    # Test cluster connectivity
    print_status "Testing cluster connectivity..."
    kubectl get nodes >> $LOG_FILE 2>&1
    if [ $? -eq 0 ]; then
      print_success "Cluster connectivity verified."
    else
      print_warning "Cluster connectivity test failed. Check $LOG_FILE for details."
    fi
  else
    print_warning "Failed to retrieve kubeconfig. Check $LOG_FILE for details."
  fi
else
  print_error "Apply failed. Check $LOG_FILE for details."
  exit 1
fi

print_success "AKS import and deployment completed successfully!"
print_status "Log file: $LOG_FILE" 