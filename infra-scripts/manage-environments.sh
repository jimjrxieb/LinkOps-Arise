#!/bin/bash

# LinkOps-Arise Environment Management Script
# Usage: ./manage-environments.sh <environment> <action>
# Example: ./manage-environments.sh demo plan

set -e

ENVIRONMENT=$1
ACTION=$2

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

# Validate inputs
if [ -z "$ENVIRONMENT" ] || [ -z "$ACTION" ]; then
    print_error "Usage: $0 <environment> <action>"
    echo "Environments: demo, personal"
    echo "Actions: init, plan, apply, destroy, output"
    exit 1
fi

# Validate environment
if [ "$ENVIRONMENT" != "demo" ] && [ "$ENVIRONMENT" != "personal" ]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: demo, personal"
    exit 1
fi

# Validate action
if [ "$ACTION" != "init" ] && [ "$ACTION" != "plan" ] && [ "$ACTION" != "apply" ] && [ "$ACTION" != "destroy" ] && [ "$ACTION" != "output" ]; then
    print_error "Invalid action: $ACTION"
    echo "Valid actions: init, plan, apply, destroy, output"
    exit 1
fi

# Set working directory (adjusted for new location in infra-scripts/)
WORKING_DIR="../$ENVIRONMENT/terraform"

# Check if directory exists
if [ ! -d "$WORKING_DIR" ]; then
    print_error "Environment directory not found: $WORKING_DIR"
    exit 1
fi

# Change to working directory
cd "$WORKING_DIR"

print_status "Working in environment: $ENVIRONMENT"
print_status "Working directory: $(pwd)"
print_status "Action: $ACTION"

# Execute Terraform command
case $ACTION in
    "init")
        print_status "Initializing Terraform..."
        terraform init
        print_success "Terraform initialized successfully"
        ;;
    "plan")
        print_status "Planning Terraform changes..."
        terraform plan
        print_success "Terraform plan completed"
        ;;
    "apply")
        print_warning "Applying Terraform changes..."
        terraform apply -auto-approve
        print_success "Terraform apply completed"
        ;;
    "destroy")
        print_warning "Destroying environment: $ENVIRONMENT"
        print_warning "This will permanently delete all resources!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy -auto-approve
            print_success "Environment destroyed successfully"
        else
            print_status "Destroy cancelled"
        fi
        ;;
    "output")
        print_status "Showing Terraform outputs..."
        terraform output
        ;;
    *)
        print_error "Unknown action: $ACTION"
        exit 1
        ;;
esac

print_success "Operation completed successfully!" 