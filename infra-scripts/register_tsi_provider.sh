#!/bin/bash

# LinkOps TimeSeriesInsights Provider Registration Script
# This script registers the Microsoft.TimeSeriesInsights provider for Azure

set -e

# Colors for output
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

# Configuration
SUBSCRIPTION_ID="e864a989-7282-4f8e-8ded-2b68911dcc95"
RESOURCE_GROUP="linkops-rg"
LOCATION="eastus"
PROVIDER_NAMESPACE="Microsoft.TimeSeriesInsights"

print_status "Starting TimeSeriesInsights provider registration..."

# Check if Azure CLI is available
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed or not in PATH"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    print_error "Not authenticated with Azure. Run 'az login' first."
    exit 1
fi

# Set subscription
print_status "Setting subscription to: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# Register the provider
print_status "Registering provider: $PROVIDER_NAMESPACE"
az provider register --namespace "$PROVIDER_NAMESPACE"

print_status "Registration initiated. Monitoring registration status..."

# Monitor registration status
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    print_status "Checking registration status (attempt $ATTEMPT/$MAX_ATTEMPTS)..."
    
    REGISTRATION_STATE=$(az provider show --namespace "$PROVIDER_NAMESPACE" --query "registrationState" -o tsv 2>/dev/null || echo "Unknown")
    
    case $REGISTRATION_STATE in
        "Registered")
            print_success "Provider $PROVIDER_NAMESPACE is now registered!"
            break
            ;;
        "Registering")
            print_status "Provider is still registering... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
            sleep 30
            ;;
        "Unregistered")
            print_warning "Provider is unregistered. Attempting to register again..."
            az provider register --namespace "$PROVIDER_NAMESPACE"
            sleep 30
            ;;
        *)
            print_warning "Unknown registration state: $REGISTRATION_STATE"
            sleep 30
            ;;
    esac
    
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    print_error "Provider registration timed out after $MAX_ATTEMPTS attempts"
    print_status "Current registration state: $REGISTRATION_STATE"
    exit 1
fi

# Final verification
print_status "Performing final verification..."
FINAL_STATE=$(az provider show --namespace "$PROVIDER_NAMESPACE" --query "registrationState" -o tsv)

if [ "$FINAL_STATE" = "Registered" ]; then
    print_success "✅ TimeSeriesInsights provider registration completed successfully!"
    print_status "Provider: $PROVIDER_NAMESPACE"
    print_status "State: $FINAL_STATE"
    print_status "Subscription: $SUBSCRIPTION_ID"
else
    print_error "❌ Provider registration failed. Final state: $FINAL_STATE"
    exit 1
fi

print_status "Script completed successfully!" 