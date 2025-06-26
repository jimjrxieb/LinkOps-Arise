#!/bin/bash

# LinkOps Git History Secret Cleanup Script
# This script helps remove hardcoded secrets from Git history using BFG Repo-Cleaner

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔐 LinkOps Git History Secret Cleanup"
echo "====================================="
echo

print_warning "This script will permanently remove secrets from Git history!"
print_warning "Make sure you have a backup of your repository before proceeding."
echo

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

# Check if BFG is installed
if ! command -v bfg &> /dev/null; then
    print_error "BFG Repo-Cleaner is not installed."
    echo
    echo "Install BFG:"
    echo "  macOS: brew install bfg"
    echo "  Linux: Download from https://rtyley.github.io/bfg-repo-cleaner/"
    echo "  Windows: Download from https://rtyley.github.io/bfg-repo-cleaner/"
    exit 1
fi

print_status "Creating secrets patterns file..."

# Create patterns file for BFG
cat > secrets-patterns.txt << 'EOF'
# Hardcoded passwords and secrets to remove
LinkOps2024!
postgres
sk-example
example
your-secret-key-here
your-openai-api-key-here
your_secure_database_password_here
your-subscription-id
your-resource-group
your-acr-name
your-key-vault-name
your-aks-cluster-name
your-service-principal-client-id
your-service-principal-client-secret
your-azure-tenant-id
your-aws-access-key
your-aws-secret-key
your-app-insights-connection-string
EOF

print_status "Running BFG to remove secrets from Git history..."

# Run BFG to replace secrets
bfg --replace-text secrets-patterns.txt

print_status "Cleaning up Git repository..."

# Clean up and optimize repository
git reflog expire --expire=now --all
git gc --prune=now --aggressive

print_success "Git history cleanup complete!"
echo
print_warning "IMPORTANT: You need to force push to update the remote repository:"
echo "  git push --force --all"
echo "  git push --force --tags"
echo
print_warning "WARNING: This will rewrite Git history. Make sure all team members are aware!"
echo
print_status "Next steps:"
echo "1. Force push to remote repository"
echo "2. Notify team members to re-clone the repository"
echo "3. Update all environment variables with new secure values"
echo "4. Rotate any exposed secrets"
echo "5. Verify no secrets remain in the codebase"
