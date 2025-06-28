#!/bin/bash

# LinkOps Kubernetes Secrets Setup Script
# This script helps create Kubernetes secrets with proper base64 encoding

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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if namespace exists, create if not
if ! kubectl get namespace linkops &> /dev/null; then
    print_status "Creating linkops namespace..."
    kubectl create namespace linkops
    print_success "Namespace 'linkops' created"
else
    print_status "Namespace 'linkops' already exists"
fi

# Function to create PostgreSQL secret
create_postgres_secret() {
    print_status "Setting up PostgreSQL secret..."
    
    # Prompt for PostgreSQL credentials
    read -p "Enter PostgreSQL username: " POSTGRES_USER
    if [[ -z "$POSTGRES_USER" ]]; then
        print_error "PostgreSQL username cannot be empty"
        exit 1
    fi
    
    read -s -p "Enter PostgreSQL password: " POSTGRES_PASSWORD
    echo
    
    read -p "Enter PostgreSQL database name (default: linkops): " POSTGRES_DB
    POSTGRES_DB=${POSTGRES_DB:-linkops}
    
    # Encode values
    POSTGRES_USER_B64=$(echo -n "$POSTGRES_USER" | base64)
    POSTGRES_PASSWORD_B64=$(echo -n "$POSTGRES_PASSWORD" | base64)
    POSTGRES_DB_B64=$(echo -n "$POSTGRES_DB" | base64)
    
    # Create secret
    kubectl create secret generic postgres-secret \
        --namespace=linkops \
        --from-literal=username="$POSTGRES_USER" \
        --from-literal=password="$POSTGRES_PASSWORD" \
        --from-literal=database="$POSTGRES_DB" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "PostgreSQL secret created"
}

# Function to create Grafana secret
create_grafana_secret() {
    print_status "Setting up Grafana secret..."
    
    # Check if password is provided via environment variable
    if [[ -z "$GRAFANA_ADMIN_PASSWORD" ]]; then
        read -s -p "Enter Grafana admin password: " GRAFANA_PASSWORD
        echo
        if [[ -z "$GRAFANA_PASSWORD" ]]; then
            print_error "Grafana admin password cannot be empty"
            exit 1
        fi
    else
        GRAFANA_PASSWORD="$GRAFANA_ADMIN_PASSWORD"
    fi
    
    # Create secret
    kubectl create secret generic grafana-secret \
        --namespace=monitoring \
        --from-literal=admin-password="$GRAFANA_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Grafana secret created"
}

# Function to create Docker registry secret
create_docker_secret() {
    print_status "Setting up Docker registry secret..."
    
    read -p "Enter Docker registry server (e.g., docker.io): " DOCKER_SERVER
    read -p "Enter Docker registry username: " DOCKER_USERNAME
    read -s -p "Enter Docker registry password: " DOCKER_PASSWORD
    echo
    read -p "Enter Docker registry email: " DOCKER_EMAIL
    
    # Create secret
    kubectl create secret docker-registry acr-secret \
        --namespace=linkops \
        --docker-server="$DOCKER_SERVER" \
        --docker-username="$DOCKER_USERNAME" \
        --docker-password="$DOCKER_PASSWORD" \
        --docker-email="$DOCKER_EMAIL" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Docker registry secret created"
}

# Function to create application secrets
create_app_secrets() {
    print_status "Setting up application secrets..."
    
    read -p "Enter database URL (e.g., postgresql://user:pass@host:5432/db): " DATABASE_URL
    read -p "Enter OpenAI API key: " OPENAI_API_KEY
    read -p "Enter ACR username: " ACR_USERNAME
    read -s -p "Enter ACR password: " ACR_PASSWORD
    echo
    
    # Create secret
    kubectl create secret generic linkops-secrets \
        --namespace=linkops \
        --from-literal=database-url="$DATABASE_URL" \
        --from-literal=openai-api-key="$OPENAI_API_KEY" \
        --from-literal=acr-username="$ACR_USERNAME" \
        --from-literal=acr-password="$ACR_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Application secrets created"
}

# Main execution
echo "🔐 LinkOps Kubernetes Secrets Setup"
echo "=================================="
echo

# Create monitoring namespace if it doesn't exist
if ! kubectl get namespace monitoring &> /dev/null; then
    print_status "Creating monitoring namespace..."
    kubectl create namespace monitoring
    print_success "Namespace 'monitoring' created"
fi

# Menu for secret creation
echo "Select which secrets to create:"
echo "1) PostgreSQL secret"
echo "2) Grafana secret"
echo "3) Docker registry secret"
echo "4) Application secrets"
echo "5) All secrets"
echo "6) Exit"
echo

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        create_postgres_secret
        ;;
    2)
        create_grafana_secret
        ;;
    3)
        create_docker_secret
        ;;
    4)
        create_app_secrets
        ;;
    5)
        create_postgres_secret
        create_grafana_secret
        create_docker_secret
        create_app_secrets
        ;;
    6)
        print_status "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo
print_success "Secrets setup complete!"
echo
echo "📋 Next steps:"
echo "1. Verify secrets were created:"
echo "   kubectl get secrets -n linkops"
echo "   kubectl get secrets -n monitoring"
echo
echo "2. Set up GitHub secrets for CI/CD:"
echo "   See docs/GITHUB_SECRETS_SETUP.md"
echo
echo "3. Deploy your application:"
echo "   kubectl apply -f infrastructure/k8s/" 