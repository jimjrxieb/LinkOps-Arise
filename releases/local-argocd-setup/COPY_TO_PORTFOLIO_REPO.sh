#!/bin/bash

# Script to copy k8s manifests to Portfolio repository
# Run this script from the LinkOps-Arise/releases/local-argocd-setup directory

set -e

PORTFOLIO_REPO_PATH=${1:-"../../../Portfolio"}

echo "🚀 Copying k8s manifests to Portfolio repository..."

if [ ! -d "$PORTFOLIO_REPO_PATH" ]; then
    echo "❌ Portfolio repository not found at: $PORTFOLIO_REPO_PATH"
    echo "Usage: $0 [portfolio-repo-path]"
    echo "Example: $0 /path/to/Portfolio"
    exit 1
fi

echo "📁 Portfolio repository found at: $PORTFOLIO_REPO_PATH"

# Create k8s-manifests directory in Portfolio repo
mkdir -p "$PORTFOLIO_REPO_PATH/k8s-manifests"

# Copy all k8s manifests
echo "📋 Copying k8s manifests..."
cp -r k8s-manifests/* "$PORTFOLIO_REPO_PATH/k8s-manifests/"

# Create additional helpful files
echo "📝 Creating additional configuration files..."

# Create .dockerignore if it doesn't exist
if [ ! -f "$PORTFOLIO_REPO_PATH/.dockerignore" ]; then
    cat > "$PORTFOLIO_REPO_PATH/.dockerignore" << 'EOF'
node_modules
.git
.gitignore
README.md
Dockerfile
.dockerignore
npm-debug.log
coverage
.nyc_output
*.md
k8s-manifests
EOF
fi

# Create GitHub Actions workflow for container builds
mkdir -p "$PORTFOLIO_REPO_PATH/.github/workflows"
cat > "$PORTFOLIO_REPO_PATH/.github/workflows/build-containers.yml" << 'EOF'
name: Build and Push Container Images

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ghcr.io/jimjrxieb/portfolio

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    strategy:
      matrix:
        service: [ui, api, chromadb, avatar-creation, rag-pipeline]

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.IMAGE_PREFIX }}-${{ matrix.service }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: ./${{ matrix.service }}
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
EOF

# Create local development docker-compose override
cat > "$PORTFOLIO_REPO_PATH/docker-compose.override.yml" << 'EOF'
version: '3.8'

# Local development overrides
# This file is automatically loaded by docker-compose
services:
  ui:
    build:
      context: ./ui
      target: development
    volumes:
      - ./ui/src:/app/src
    environment:
      - NODE_ENV=development

  api:
    build:
      context: ./api
      target: development
    volumes:
      - ./api:/app
    environment:
      - DEBUG=True
      - RELOAD=True

  # Add development overrides for other services as needed
EOF

# Create deployment helper script
cat > "$PORTFOLIO_REPO_PATH/deploy-to-k8s.sh" << 'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying Portfolio to Kubernetes..."

# Build and push images
echo "🏗️  Building container images..."
services=("ui" "api" "chromadb" "avatar-creation" "rag-pipeline")

for service in "${services[@]}"; do
    echo "Building $service..."
    docker build -t ghcr.io/jimjrxieb/portfolio-$service:latest ./$service
    docker push ghcr.io/jimjrxieb/portfolio-$service:latest
done

# Apply manifests
echo "📋 Applying Kubernetes manifests..."
kubectl apply -k k8s-manifests/

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n portfolio

echo "✅ Deployment complete!"
echo "🌐 Access your application:"
echo "   UI: http://localhost (via LoadBalancer)"
echo "   API: http://localhost/api"
echo "   ArgoCD: https://localhost:8080"
EOF

chmod +x "$PORTFOLIO_REPO_PATH/deploy-to-k8s.sh"

echo "✅ Files copied successfully to Portfolio repository!"
echo ""
echo "📋 Files created/updated:"
echo "  - k8s-manifests/ (complete Kubernetes manifests)"
echo "  - .dockerignore"
echo "  - .github/workflows/build-containers.yml"
echo "  - docker-compose.override.yml"
echo "  - deploy-to-k8s.sh"
echo ""
echo "🔧 Next steps:"
echo "  1. cd $PORTFOLIO_REPO_PATH"
echo "  2. Update k8s-manifests/secret.yaml with real API keys"
echo "  3. Build and push initial images: ./deploy-to-k8s.sh"
echo "  4. Commit and push to trigger CI/CD"