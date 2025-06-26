#!/bin/bash

# LinkOps Terraform Deployment Script
# This script automates the deployment of LinkOps infrastructure on Azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. You'll need it to interact with the cluster."
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_warning "helm is not installed. You'll need it for some deployments."
    fi
    
    print_success "Prerequisites check completed"
}

# Check Azure authentication
check_azure_auth() {
    print_status "Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
        print_error "Not authenticated with Azure. Please run 'az login' first."
        exit 1
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    
    print_success "Authenticated with Azure"
    print_status "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    if [ ! -d ".terraform" ]; then
        terraform init
        print_success "Terraform initialized"
    else
        print_status "Terraform already initialized"
    fi
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    terraform plan -out=tfplan
    
    print_success "Terraform plan created"
    print_warning "Review the plan above before proceeding"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    if [ ! -f "tfplan" ]; then
        print_error "No Terraform plan found. Run 'terraform plan' first."
        exit 1
    fi
    
    terraform apply tfplan
    
    print_success "Terraform deployment completed"
}

# Configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl..."
    
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
    
    print_success "kubectl configured for AKS cluster"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check cluster status
    print_status "Checking AKS cluster status..."
    kubectl cluster-info
    
    # Check nodes
    print_status "Checking AKS nodes..."
    kubectl get nodes
    
    # Check ingress controller
    print_status "Checking NGINX ingress controller..."
    kubectl get pods -n ingress-nginx
    
    # Get ACR info
    print_status "Getting ACR information..."
    ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
    print_success "ACR Login Server: $ACR_LOGIN_SERVER"
    
    print_success "Deployment verification completed"
}

# Show outputs
show_outputs() {
    print_status "Deployment outputs:"
    echo ""
    terraform output
    echo ""
    
    print_success "Deployment completed successfully!"
    print_status "Next steps:"
    echo "1. Build and push your microservices to ACR"
    echo "2. Deploy applications using Kubernetes manifests"
    echo "3. Configure ingress rules for external access"
}

# Main deployment function
deploy() {
    print_status "Starting LinkOps infrastructure deployment..."
    echo ""
    
    check_prerequisites
    check_azure_auth
    init_terraform
    plan_terraform
    
    echo ""
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        configure_kubectl
        verify_deployment
        show_outputs
    else
        print_warning "Deployment cancelled by user"
        exit 0
    fi
}

# Destroy function
destroy() {
    print_warning "This will destroy all LinkOps infrastructure!"
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying infrastructure..."
        terraform destroy
        print_success "Infrastructure destroyed"
    else
        print_warning "Destruction cancelled by user"
    fi
}

# Help function
show_help() {
    echo "LinkOps Terraform Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy   - Deploy the LinkOps infrastructure (default)"
    echo "  destroy  - Destroy the LinkOps infrastructure"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 destroy"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    destroy)
        destroy
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 