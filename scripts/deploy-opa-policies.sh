#!/bin/bash
# Deploy OPA Gatekeeper Policies for CKS Learning

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
POLICIES_DIR="${PROJECT_ROOT}/opa-policies"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_header() {
    echo -e "${BLUE}[CKS-POLICY]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_header "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    # Check if Gatekeeper is installed
    if ! kubectl get namespace gatekeeper-system &> /dev/null; then
        log_error "Gatekeeper is not installed. Please install Gatekeeper first:"
        echo "  helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts"
        echo "  helm install gatekeeper gatekeeper/gatekeeper --create-namespace --namespace gatekeeper-system"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Deploy constraint templates
deploy_constraint_templates() {
    log_header "Deploying OPA Gatekeeper Constraint Templates..."

    # Security constraint templates
    log_info "Deploying security constraint templates..."
    kubectl apply -f "${POLICIES_DIR}/security/required-security-context.yaml"
    kubectl apply -f "${POLICIES_DIR}/security/disallow-privileged-containers.yaml"
    kubectl apply -f "${POLICIES_DIR}/security/required-resource-limits.yaml"
    kubectl apply -f "${POLICIES_DIR}/security/allowed-image-registries.yaml"

    # Compliance constraint templates
    log_info "Deploying compliance constraint templates..."
    kubectl apply -f "${POLICIES_DIR}/compliance/pod-security-standards.yaml"

    # Governance constraint templates
    log_info "Deploying governance constraint templates..."
    kubectl apply -f "${POLICIES_DIR}/governance/required-labels.yaml"

    log_info "Constraint templates deployed successfully"
}

# Deploy mutating policies
deploy_mutating_policies() {
    log_header "Deploying OPA Gatekeeper Mutating Policies..."

    # Check if mutations are enabled
    if ! kubectl get crd assigns.mutations.gatekeeper.sh &> /dev/null; then
        log_warn "Gatekeeper mutations are not enabled. Skipping mutating policies."
        log_info "To enable mutations, upgrade Gatekeeper with mutations enabled"
        return
    fi

    kubectl apply -f "${POLICIES_DIR}/security/mutating-policies.yaml"
    log_info "Mutating policies deployed successfully"
}

# Wait for constraint templates to be ready
wait_for_templates() {
    log_header "Waiting for constraint templates to be ready..."

    templates=(
        "k8srequiredsecuritycontext"
        "k8sdisallowprivileged"
        "k8sdisallowhostnamespace"
        "k8srequiredresources"
        "k8sallowedrepos"
        "k8sdisallowlatesttag"
        "k8spodsecuritystandards"
        "k8srequiredlabels"
        "k8srequiredannotations"
    )

    for template in "${templates[@]}"; do
        log_info "Waiting for template $template to be ready..."
        kubectl wait --for=condition=Established --timeout=300s constrainttemplate/$template
    done

    log_info "All constraint templates are ready"
}

# Check policy status
check_policy_status() {
    log_header "Checking OPA Gatekeeper Policy Status..."

    echo -e "\n${BLUE}Constraint Templates:${NC}"
    kubectl get constrainttemplates

    echo -e "\n${BLUE}Constraints:${NC}"
    kubectl get constraints

    echo -e "\n${BLUE}Gatekeeper Violations:${NC}"
    kubectl get events --field-selector reason=ConstraintViolation --all-namespaces | head -10

    echo -e "\n${BLUE}Gatekeeper System Status:${NC}"
    kubectl get pods -n gatekeeper-system
}

# Test policies with sample violations
test_policies() {
    log_header "Testing policies with sample violations..."

    # Create test namespace
    kubectl create namespace policy-test --dry-run=client -o yaml | kubectl apply -f -

    # Test 1: Pod without security context (should be rejected/warned)
    log_info "Testing policy: Pod without security context"
    cat <<EOF | kubectl apply --dry-run=server -f - || log_warn "Policy violation detected (expected)"
apiVersion: v1
kind: Pod
metadata:
  name: test-insecure-pod
  namespace: policy-test
spec:
  containers:
  - name: test
    image: nginx:latest
EOF

    # Test 2: Privileged pod (should be rejected)
    log_info "Testing policy: Privileged pod"
    cat <<EOF | kubectl apply --dry-run=server -f - || log_warn "Policy violation detected (expected)"
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged-pod
  namespace: policy-test
spec:
  containers:
  - name: test
    image: nginx:1.21
    securityContext:
      privileged: true
EOF

    # Test 3: Pod with proper security context (should be accepted)
    log_info "Testing policy: Pod with proper security context"
    cat <<EOF | kubectl apply --dry-run=server -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-secure-pod
  namespace: policy-test
  labels:
    app.kubernetes.io/name: test-app
    app.kubernetes.io/version: "1.0"
    app.kubernetes.io/managed-by: kubectl
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: test
    image: nginx:1.21
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1001
      capabilities:
        drop: ["ALL"]
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF

    log_info "Policy testing completed"
}

# Main deployment function
main() {
    log_header "Starting OPA Gatekeeper Policy Deployment for CKS Learning"

    check_prerequisites
    deploy_constraint_templates
    wait_for_templates
    deploy_mutating_policies
    check_policy_status
    test_policies

    log_header "OPA Gatekeeper Policy Deployment Complete!"

    echo -e "\n${GREEN}Next Steps:${NC}"
    echo "1. Review policy violations: kubectl get events --field-selector reason=ConstraintViolation --all-namespaces"
    echo "2. Test with your applications: kubectl apply -f your-app.yaml"
    echo "3. Adjust enforcement actions from 'warn' to 'deny' when ready"
    echo "4. Monitor Gatekeeper metrics and logs"

    echo -e "\n${YELLOW}CKS Learning Resources:${NC}"
    echo "- Constraint Templates: kubectl get constrainttemplates"
    echo "- Policy Violations: kubectl describe constraint <constraint-name>"
    echo "- Gatekeeper Logs: kubectl logs -n gatekeeper-system -l control-plane=controller-manager"
}

# Run main function
main "$@"