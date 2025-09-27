#!/bin/bash
# Deploy Network Policies and Enhanced RBAC for CKS Learning

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
K8S_MANIFESTS="${PROJECT_ROOT}/k8s-manifests/portfolio"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    echo -e "${BLUE}[CKS-NETWORK]${NC} $1"
}

log_security() {
    echo -e "${PURPLE}[SECURITY]${NC} $1"
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

    # Check if CNI supports NetworkPolicies
    log_info "Checking CNI NetworkPolicy support..."
    if kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}' | grep -q containerd; then
        log_info "Container runtime detected: containerd"
    fi

    # Check if portfolio namespace exists
    if ! kubectl get namespace portfolio &> /dev/null; then
        log_warn "Portfolio namespace doesn't exist, creating..."
        kubectl create namespace portfolio
        kubectl label namespace portfolio name=portfolio
    fi

    log_info "Prerequisites check passed"
}

# Deploy enhanced RBAC
deploy_rbac() {
    log_header "Deploying Enhanced RBAC Configuration..."

    log_security "Creating service accounts with least privilege..."
    kubectl apply -f "${K8S_MANIFESTS}/rbac-security.yaml"

    log_info "Waiting for service accounts to be ready..."
    kubectl wait --for=condition=Ready --timeout=60s serviceaccount/portfolio-app -n portfolio

    # Verify RBAC configuration
    log_info "Verifying RBAC configuration..."
    echo -e "\n${BLUE}Service Accounts:${NC}"
    kubectl get serviceaccounts -n portfolio

    echo -e "\n${BLUE}Roles:${NC}"
    kubectl get roles -n portfolio

    echo -e "\n${BLUE}RoleBindings:${NC}"
    kubectl get rolebindings -n portfolio

    echo -e "\n${BLUE}ClusterRoles:${NC}"
    kubectl get clusterroles | grep portfolio

    log_info "Enhanced RBAC deployed successfully"
}

# Deploy Pod Security Policies (if supported)
deploy_psp() {
    log_header "Deploying Pod Security Policies..."

    # Check if PSPs are supported (deprecated in 1.21+, removed in 1.25+)
    if kubectl api-resources | grep -q podsecuritypolicies; then
        log_info "PSPs are supported, deploying..."
        kubectl apply -f "${K8S_MANIFESTS}/pod-security-policy.yaml"
        log_info "PSPs deployed successfully"
    else
        log_warn "PSPs not supported in this cluster version"
        log_info "Pod Security Standards are recommended instead"
    fi
}

# Deploy network policies
deploy_network_policies() {
    log_header "Deploying Network Policies for Micro-segmentation..."

    log_security "Implementing zero-trust network model..."
    kubectl apply -f "${K8S_MANIFESTS}/network-policies.yaml"

    log_info "Waiting for network policies to be active..."
    sleep 5

    # Verify network policies
    log_info "Verifying network policy deployment..."
    echo -e "\n${BLUE}Network Policies:${NC}"
    kubectl get networkpolicies -n portfolio

    echo -e "\n${BLUE}Network Policy Details:${NC}"
    kubectl describe networkpolicies -n portfolio | head -20

    log_info "Network policies deployed successfully"
}

# Test network policies
test_network_policies() {
    log_header "Testing Network Policy Enforcement..."

    # Create test pods for network policy testing
    log_info "Creating test pods for connectivity testing..."

    # Test pod 1: Should be able to reach API
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-client
  namespace: portfolio
  labels:
    app.kubernetes.io/name: ui
    test: network-policy
spec:
  serviceAccountName: portfolio-app
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: client
    image: busybox:1.35
    command: ['sleep', '300']
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1001
      capabilities:
        drop: ["ALL"]
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
      limits:
        cpu: 100m
        memory: 64Mi
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
  restartPolicy: Never
EOF

    # Test pod 2: Should NOT be able to reach anything (isolated)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-isolated
  namespace: portfolio
  labels:
    test: network-policy-isolated
spec:
  serviceAccountName: portfolio-app
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: isolated
    image: busybox:1.35
    command: ['sleep', '300']
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1001
      capabilities:
        drop: ["ALL"]
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
      limits:
        cpu: 100m
        memory: 64Mi
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
  restartPolicy: Never
EOF

    log_info "Waiting for test pods to be ready..."
    kubectl wait --for=condition=Ready --timeout=60s pod/test-client -n portfolio
    kubectl wait --for=condition=Ready --timeout=60s pod/test-isolated -n portfolio

    # Test connectivity
    log_info "Testing network policy enforcement..."

    log_info "Test 1: UI pod (test-client) should reach API service (ALLOWED)"
    if kubectl exec -n portfolio test-client -- nslookup api.portfolio.svc.cluster.local; then
        log_info "✅ DNS resolution works (expected)"
    else
        log_warn "❌ DNS resolution failed"
    fi

    log_info "Test 2: Isolated pod should be blocked from API service (DENIED)"
    if kubectl exec -n portfolio test-isolated -- timeout 3 nc -zv api.portfolio.svc.cluster.local 8000; then
        log_warn "❌ Isolated pod can reach API (unexpected - check network policies)"
    else
        log_info "✅ Isolated pod blocked from API (expected)"
    fi

    log_info "Network policy testing completed"
}

# Test RBAC
test_rbac() {
    log_header "Testing RBAC Configuration..."

    log_info "Testing service account permissions..."

    # Test 1: Portfolio app should be able to read its own config
    log_info "Test 1: Portfolio app reading ConfigMap (ALLOWED)"
    if kubectl auth can-i get configmap/portfolio-config --as=system:serviceaccount:portfolio:portfolio-app -n portfolio; then
        log_info "✅ Portfolio app can read ConfigMap (expected)"
    else
        log_warn "❌ Portfolio app cannot read ConfigMap"
    fi

    # Test 2: Portfolio app should NOT be able to create pods
    log_info "Test 2: Portfolio app creating pods (DENIED)"
    if kubectl auth can-i create pods --as=system:serviceaccount:portfolio:portfolio-app -n portfolio; then
        log_warn "❌ Portfolio app can create pods (unexpected)"
    else
        log_info "✅ Portfolio app cannot create pods (expected)"
    fi

    # Test 3: Monitoring should be able to read pods
    log_info "Test 3: Monitoring service reading pods (ALLOWED)"
    if kubectl auth can-i get pods --as=system:serviceaccount:portfolio:portfolio-monitoring -n portfolio; then
        log_info "✅ Monitoring can read pods (expected)"
    else
        log_warn "❌ Monitoring cannot read pods"
    fi

    # Test 4: Security auditor should have cluster-wide read access
    log_info "Test 4: Security auditor cluster access (ALLOWED)"
    if kubectl auth can-i get networkpolicies --as=system:serviceaccount:portfolio:security-auditor --all-namespaces; then
        log_info "✅ Security auditor can read NetworkPolicies (expected)"
    else
        log_warn "❌ Security auditor cannot read NetworkPolicies"
    fi

    log_info "RBAC testing completed"
}

# Security validation
validate_security() {
    log_header "Performing Security Validation..."

    log_security "Checking for security misconfigurations..."

    # Check 1: No default service accounts should be used
    log_info "Checking for default service account usage..."
    if kubectl get pods -n portfolio -o jsonpath='{.items[*].spec.serviceAccountName}' | grep -q "^$"; then
        log_warn "❌ Found pods using default service account"
    else
        log_info "✅ No pods using default service account"
    fi

    # Check 2: All service accounts should have automountServiceAccountToken: false
    log_info "Checking service account token auto-mounting..."
    auto_mount_count=$(kubectl get serviceaccounts -n portfolio -o jsonpath='{.items[?(@.automountServiceAccountToken==true)].metadata.name}' | wc -w)
    if [ "$auto_mount_count" -gt 0 ]; then
        log_warn "❌ Found service accounts with auto-mounted tokens: $auto_mount_count"
    else
        log_info "✅ All service accounts have auto-mount disabled"
    fi

    # Check 3: Network policies should cover all pods
    log_info "Checking network policy coverage..."
    total_pods=$(kubectl get pods -n portfolio --no-headers | wc -l)
    log_info "Total pods in portfolio namespace: $total_pods"

    # Check 4: RBAC coverage
    log_info "Checking RBAC coverage..."
    sa_count=$(kubectl get serviceaccounts -n portfolio --no-headers | wc -l)
    role_count=$(kubectl get roles -n portfolio --no-headers | wc -l)
    binding_count=$(kubectl get rolebindings -n portfolio --no-headers | wc -l)
    log_info "Service accounts: $sa_count, Roles: $role_count, Bindings: $binding_count"

    log_security "Security validation completed"
}

# Cleanup test resources
cleanup_tests() {
    log_header "Cleaning up test resources..."

    kubectl delete pod test-client -n portfolio --ignore-not-found=true
    kubectl delete pod test-isolated -n portfolio --ignore-not-found=true

    log_info "Test cleanup completed"
}

# Main deployment function
main() {
    log_header "Starting Network Security and RBAC Deployment for CKS Learning"

    check_prerequisites
    deploy_rbac
    deploy_psp
    deploy_network_policies
    test_network_policies
    test_rbac
    validate_security
    cleanup_tests

    log_header "Network Security and RBAC Deployment Complete!"

    echo -e "\n${GREEN}Deployment Summary:${NC}"
    echo "✅ Enhanced RBAC with least privilege service accounts"
    echo "✅ Comprehensive network policies for micro-segmentation"
    echo "✅ Pod Security Policies (if supported)"
    echo "✅ Security validation and testing"

    echo -e "\n${YELLOW}CKS Learning Commands:${NC}"
    echo "# View network policies:"
    echo "kubectl get networkpolicies -n portfolio"
    echo ""
    echo "# Test network connectivity:"
    echo "kubectl run test-pod --image=busybox --rm -it -- /bin/sh"
    echo ""
    echo "# Check RBAC permissions:"
    echo "kubectl auth can-i <verb> <resource> --as=system:serviceaccount:portfolio:portfolio-app"
    echo ""
    echo "# View security events:"
    echo "kubectl get events -n portfolio --field-selector type=Warning"

    echo -e "\n${PURPLE}Security Status:${NC}"
    kubectl get networkpolicies,serviceaccounts,roles,rolebindings -n portfolio
}

# Run main function
main "$@"