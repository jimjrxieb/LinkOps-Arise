#!/bin/bash
# CKS Security: Apply security contexts to all portfolio deployments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../k8s-manifests/portfolio"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to add security context to a deployment file
add_security_context() {
    local file="$1"
    local service_name="$2"

    log_info "Adding security context to $service_name..."

    # Check if security context already exists
    if grep -q "securityContext:" "$file"; then
        log_warn "Security context already exists in $file, skipping..."
        return
    fi

    # Create backup
    cp "$file" "${file}.backup"

    # Use sed to add pod security context after 'spec:' line
    sed -i '/^    spec:$/a\      # CKS Security: Pod security context\
      securityContext:\
        runAsNonRoot: true\
        runAsUser: 1001\
        runAsGroup: 1001\
        fsGroup: 1001\
        seccompProfile:\
          type: RuntimeDefault' "$file"

    # Add container security context after 'image:' line
    sed -i '/image: ghcr.io/a\        # CKS Security: Container security context\
        securityContext:\
          allowPrivilegeEscalation: false\
          readOnlyRootFilesystem: true\
          runAsNonRoot: true\
          runAsUser: 1001\
          runAsGroup: 1001\
          capabilities:\
            drop:\
            - ALL\
            add:\
            - NET_BIND_SERVICE' "$file"

    # Add tmp volumes if volumeMounts exist
    if grep -q "volumeMounts:" "$file"; then
        # Add tmp volume mounts
        sed -i '/volumeMounts:/a\        - name: tmp-volume\
          mountPath: /tmp\
        - name: var-tmp-volume\
          mountPath: /var/tmp' "$file"

        # Add tmp volumes
        sed -i '/volumes:/a\      - name: tmp-volume\
        emptyDir: {}\
      - name: var-tmp-volume\
        emptyDir: {}' "$file"
    fi

    log_info "Security context added to $service_name"
}

# Apply security contexts to all deployment files
for file in "$MANIFESTS_DIR"/*.yaml; do
    if [[ -f "$file" ]] && grep -q "kind: Deployment" "$file"; then
        service_name=$(basename "$file" .yaml)

        # Skip api.yaml as we already modified it
        if [[ "$service_name" == "api" ]]; then
            log_info "Skipping $service_name (already configured)"
            continue
        fi

        add_security_context "$file" "$service_name"
    fi
done

log_info "Security context application complete!"
log_warn "Backups created with .backup extension"
log_info "Next steps:"
echo "  1. Review the changes in git diff"
echo "  2. Test deployments with: kubectl apply -f k8s-manifests/portfolio/"
echo "  3. Verify pods start with: kubectl get pods -n portfolio"