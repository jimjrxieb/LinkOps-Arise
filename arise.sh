#!/bin/bash

set -e

echo "🔐 Checking for stale Terraform state lock..."
LOCK_ID=$(terraform force-unlock -dry-run 2>&1 | grep -oE "[a-f0-9-]{36}" || true)
[ -n "$LOCK_ID" ] && terraform force-unlock "$LOCK_ID" || echo "✅ No lock to release."

echo "🚀 Initializing Terraform..."
terraform init -upgrade

echo "📐 Planning infrastructure changes..."
terraform plan -lock-timeout=60s
