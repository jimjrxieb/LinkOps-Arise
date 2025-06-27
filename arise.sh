#!/bin/bash
# Rune: Fix AKS API version and deploy
# Usage: ./deploy_aks_fix_api.sh
# Store in LinkOps-Arise/scripts/deploy_aks_fix_api.sh

# Variables (adjust based on LinkOps-Arise setup)
TF_STATE_PATH="tfstate/linkops.tfstate"
AZURE_STORAGE_ACCOUNT="tfstate"
AZURE_CONTAINER="tfstate"
RESOURCE_GROUP="state-rg"
SUBSCRIPTION_ID="e864a989-7282-4f8e-8ded-2b68911dcc95"
LOG_FILE="aks_deployment.log"
K8S_VERSION="1.27.9"
API_VERSION="2023-10-01"

echo "Starting AKS deployment with API version fix..." | tee -a $LOG_FILE

# Check for active Terraform processes
echo "Checking for active Terraform processes..." | tee -a $LOG_FILE
if ps aux | grep -v grep | grep terraform >/dev/null; then
  echo "Error: Active Terraform process found. Terminate it before continuing." | tee -a $LOG_FILE
  exit 1
fi

# Verify Azure storage account and container
echo "Verifying storage account and container..." | tee -a $LOG_FILE
az storage account show --name "$AZURE_STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Storage account $AZURE_STORAGE_ACCOUNT not found in $RESOURCE_GROUP." | tee -a $LOG_FILE
  exit 1
fi
az storage container show --name "$AZURE_CONTAINER" --account-name "$AZURE_STORAGE_ACCOUNT" >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Container $AZURE_CONTAINER not found in $AZURE_STORAGE_ACCOUNT." | tee -a $LOG_FILE
  exit 1
fi

# Validate Kubernetes version
echo "Validating Kubernetes version $K8S_VERSION..." | tee -a $LOG_FILE
if az aks get-versions --location eastus | grep "$K8S_VERSION" >/dev/null; then
  echo "Kubernetes version $K8S_VERSION is supported." | tee -a $LOG_FILE
else
  echo "Error: Kubernetes version $K8S_VERSION not supported in eastus. Run 'az aks get-versions --location eastus' for valid versions." | tee -a $LOG_FILE
  exit 1
fi

# Validate AKS API version
echo "Validating AKS API version $API_VERSION..." | tee -a $LOG_FILE
if az provider show --namespace Microsoft.ContainerService | grep "$API_VERSION" >/dev/null; then
  echo "API version $API_VERSION is supported." | tee -a $LOG_FILE
else
  echo "Error: API version $API_VERSION not supported. Run 'az provider show --namespace Microsoft.ContainerService' for valid versions." | tee -a $LOG_FILE
  exit 1
fi

# Update provider.tf to ensure compatible azurerm version
echo "Updating provider configuration..." | tee -a $LOG_FILE
cat > provider.tf << EOF
provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
}
EOF

# Initialize Terraform
echo "Initializing Terraform..." | tee -a $LOG_FILE
terraform init >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Terraform init failed. Check backend config and credentials." | tee -a $LOG_FILE
  exit 1
fi

# Generate and apply Terraform plan
echo "Generating Terraform plan..." | tee -a $LOG_FILE
terraform plan -lock-timeout=30s -out=tfplan >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Plan failed. Check $LOG_FILE for details." | tee -a $LOG_FILE
  exit 1
fi

echo "Applying Terraform configuration..." | tee -a $LOG_FILE
terraform apply tfplan >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  echo "AKS deployment successful! Outputs in $LOG_FILE." | tee -a $LOG_FILE
  # Retrieve kubeconfig
  az aks get-credentials --resource-group linkops-rg --name linkops-aks >> $LOG_FILE 2>&1
  kubectl get nodes >> $LOG_FILE 2>&1
else
  echo "Error: Deployment failed. Check $LOG_FILE for details." | tee -a $LOG_FILE
  exit 1
fi