#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up local ArgoCD + Portfolio deployment${NC}"

# Check if Docker Desktop Kubernetes is running
if ! kubectl cluster-info --context docker-desktop &> /dev/null; then
    echo -e "${RED}❌ Docker Desktop Kubernetes is not running!${NC}"
    echo -e "${YELLOW}Please enable Kubernetes in Docker Desktop and try again.${NC}"
    exit 1
fi

# Ensure kubectl context is Docker Desktop
echo -e "${BLUE}🔧 Setting kubectl context to docker-desktop...${NC}"
kubectl config use-context docker-desktop

# Create argocd namespace
echo -e "${BLUE}📦 Creating ArgoCD namespace...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm is not installed!${NC}"
    echo -e "${YELLOW}Please install Helm: https://helm.sh/docs/intro/install/${NC}"
    exit 1
fi

# Add ArgoCD Helm repository
echo -e "${BLUE}📦 Adding ArgoCD Helm repository...${NC}"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD via Helm
echo -e "${BLUE}🚀 Installing ArgoCD via Helm...${NC}"
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer \
  --set server.extraArgs='{--insecure}' \
  --set configs.params."server\.insecure"=true \
  --set server.ingress.enabled=false \
  --wait \
  --timeout=10m

# Wait for ArgoCD to be ready
echo -e "${YELLOW}⏳ Waiting for ArgoCD to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get ArgoCD admin password
echo -e "${BLUE}🔑 Getting ArgoCD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Create a script to manage port-forward
cat > /tmp/argocd-port-forward.sh << 'EOF'
#!/bin/bash
echo "🌐 Starting ArgoCD UI port-forward on https://localhost:8080"
echo "Press Ctrl+C to stop"
kubectl port-forward svc/argocd-server -n argocd 8080:443
EOF
chmod +x /tmp/argocd-port-forward.sh

# Create portfolio namespace for the application
echo -e "${BLUE}📦 Creating portfolio namespace...${NC}"
kubectl create namespace portfolio --dry-run=client -o yaml | kubectl apply -f -

# Apply ArgoCD applications if they exist
if [ -f "../argocd-apps/portfolio-app.yaml" ]; then
    echo -e "${BLUE}📱 Applying Portfolio ArgoCD application...${NC}"
    kubectl apply -f ../argocd-apps/portfolio-app.yaml
fi

echo -e "${GREEN}✅ ArgoCD Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}🔗 ArgoCD UI:${NC} https://localhost:8080"
echo -e "${BLUE}👤 Username:${NC} admin"
echo -e "${BLUE}🔒 Password:${NC} $ARGOCD_PASSWORD"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}To access ArgoCD UI:${NC}"
echo -e "1. Run: ${BLUE}/tmp/argocd-port-forward.sh${NC}"
echo -e "2. Open: ${BLUE}https://localhost:8080${NC}"
echo -e "3. Login with admin/$ARGOCD_PASSWORD"
echo ""
echo -e "${YELLOW}To apply Portfolio application:${NC}"
echo -e "kubectl apply -f argocd-apps/portfolio-app.yaml"
echo ""
echo -e "${YELLOW}ArgoCD CLI setup (optional):${NC}"
echo -e "argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure"