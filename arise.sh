#!/bin/bash

# LinkOps Terraform Deployment Script (a.k.a. Arise)

set -e
trap 'print_error "Script failed unexpectedly. Check logs or last command."' ERR

# Optional: capture log output
exec > >(tee -i arise.log)
exec 2>&1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Output helpers
print_status()   { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success()  { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning()  { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()    { echo -e "${RED}[ERROR]${NC} $1"; }

# Optional: auto-approve via --auto-approve
AUTO_APPROVE=""
[[ "$2" == "--auto-approve" ]] && AUTO_APPROVE="true"

# Default Grafana password if not set
: "${TF_VAR_grafana_admin_password:=ShadowGrafana!2025}"
export TF_VAR_grafana_admin_password

force_unlock() {
    print_status "Checking for stale Terraform state lock..."
    terraform force-unlock $(terraform force-unlock -dry-run 2>&1 | grep -oE "[a-f0-9-]{36}") 2>/dev/null || true
}

check_prerequisites() {
    print_status "Checking prerequisites..."
    command -v az >/dev/null || { print_error "Azure CLI is not installed."; exit 1; }
    command -v terraform >/dev/null || { print_error "Terraform is not installed."; exit 1; }
    command -v kubectl >/dev/null || print_warning "kubectl not installed."
    command -v helm >/dev/null || print_warning "helm not installed."
    print_success "All required tools are present"
}

check_azure_auth() {
    print_status "Checking Azure authentication..."
    if ! az account show &> /dev/null; then
        print_error "Not authenticated with Azure. Run 'az login' first."
        exit 1
    fi
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    print_success "Authenticated to Azure"
    print_status "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
}

init_terraform() {
    print_status "Initializing Terraform..."
    terraform init -reconfigure -upgrade
    print_success "Terraform initialized"
}

plan_terraform() {
    print_status "Planning Terraform deployment..."
    force_unlock
    terraform plan -lock-timeout=60s -out=tfplan
    print_success "Terraform plan created"
    print_warning "Review the plan before applying"
}

apply_terraform() {
    print_status "Applying Terraform deployment..."
    if [ ! -f "tfplan" ]; then
        print_error "No plan file found. Run 'terraform plan' first."
        exit 1
    fi
    terraform apply -lock-timeout=60s ${AUTO_APPROVE:+-auto-approve} tfplan
    print_success "Terraform apply completed"
}

configure_kubectl() {
    print_status "Configuring kubectl..."
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
    print_success "kubectl configured for $CLUSTER_NAME"
}

verify_deployment() {
    print_status "Verifying AKS cluster and components..."
    kubectl cluster-info
    kubectl get nodes
    print_status "Checking ingress-nginx pods..."
    kubectl get pods -n ingress-nginx || print_warning "Ingress controller not found"
    ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server 2>/dev/null || echo "N/A")
    print_success "ACR Login Server: $ACR_LOGIN_SERVER"
}

show_outputs() {
    print_status "Terraform Outputs:"
    terraform output
    print_success "Infrastructure ready"
    print_status "Next steps:"
    echo "1. Build & push microservices to ACR"
    echo "2. Deploy apps via manifests (LinkOps-Manifests)"
    echo "3. Configure Ingress if needed"
}

deploy() {
    print_status "🚀 Starting LinkOps Infrastructure Deployment"
    check_prerequisites
    check_azure_auth
    init_terraform
    plan_terraform

    echo ""
    read -p "Proceed with deployment? (y/N): " -n 1 -r
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

destroy() {
    print_warning "⚠️  This will destroy all LinkOps infrastructure!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform destroy
        print_success "Infrastructure destroyed"
    else
        print_warning "Destruction cancelled"
    fi
}

show_help() {
    echo "LinkOps Infrastructure CLI (arise.sh)"
    echo ""
    echo "Usage: ./arise.sh [COMMAND] [--auto-approve]"
    echo ""
    echo "Commands:"
    echo "  deploy       Deploy LinkOps Infra (default)"
    echo "  destroy      Tear down all resources"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./arise.sh"
    echo "  ./arise.sh deploy --auto-approve"
    echo "  ./arise.sh destroy"
}

# CLI Routing
case "${1:-deploy}" in
    deploy) deploy ;;
    destroy) destroy ;;
    help|--help|-h) show_help ;;
    *) print_error "Unknown command: $1"; show_help; exit 1 ;;
esac
