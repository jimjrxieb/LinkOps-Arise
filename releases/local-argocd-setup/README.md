# Local ArgoCD + Portfolio Setup

## Overview
Complete local development setup for deploying Portfolio application using ArgoCD on Docker Desktop Kubernetes.

## Architecture
```
Docker Desktop Kubernetes
├── ArgoCD (GitOps Controller)
│   ├── Namespace: argocd
│   ├── UI: https://localhost:8080
│   └── Applications: portfolio, monitoring
└── Portfolio Application
    ├── Namespace: portfolio
    ├── Services: UI, API, ChromaDB, Avatar Creation, RAG Pipeline
    └── Access: http://localhost (LoadBalancer)
```

## Prerequisites
1. **Docker Desktop** with Kubernetes enabled
2. **Helm** installed (`brew install helm`)
3. **kubectl** configured for docker-desktop context

## Quick Start

### 1. Deploy ArgoCD
```bash
# From LinkOps-Arise root directory
cd scripts
./deploy-local.sh
```

### 2. Access ArgoCD UI
```bash
# Run the port-forward script (created by deploy-local.sh)
/tmp/argocd-port-forward.sh
```
- URL: https://localhost:8080
- Username: `admin`
- Password: (displayed after deployment)

### 3. Deploy Portfolio Application
```bash
# Apply the Portfolio ArgoCD application
kubectl apply -f argocd-apps/portfolio-app.yaml
```

### 4. Access Portfolio Application
```bash
# Check LoadBalancer service
kubectl get svc portfolio-loadbalancer -n portfolio

# Access at: http://localhost (once LoadBalancer gets external IP)
```

## Repository Structure

### LinkOps-Arise (GitOps Repository)
```
LinkOps-Arise/
├── scripts/
│   └── deploy-local.sh              # ArgoCD installation script
├── argocd-apps/
│   ├── portfolio-app.yaml           # Portfolio ArgoCD application
│   └── monitoring-apps.yaml         # Monitoring ArgoCD applications
├── k8s-manifests/portfolio/         # Kubernetes manifests (for reference)
└── releases/local-argocd-setup/     # This release package
```

### Portfolio Repository (Application Code)
You need to copy the k8s-manifests to your Portfolio repository:

```
Portfolio/
├── src/                            # Application source code
├── k8s-manifests/                  # Copy from LinkOps-Arise/k8s-manifests/portfolio/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── chromadb.yaml
│   ├── avatar-creation.yaml
│   ├── rag-pipeline.yaml
│   ├── api.yaml
│   ├── ui.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
└── Dockerfiles/                    # Container definitions
```

## Service Details

### ChromaDB (Vector Database)
- **Port**: 8000
- **Purpose**: Vector database for RAG pipeline
- **Health Check**: `/api/v1/heartbeat`

### Avatar Creation Service
- **Port**: 8000
- **Purpose**: AI avatar generation with Gojo character
- **Dependencies**: OpenAI API, ChromaDB

### RAG Pipeline
- **Ports**: 8888 (Jupyter), 8000 (API)
- **Purpose**: Retrieval Augmented Generation pipeline
- **Access**: Jupyter Lab for development

### API (Backend)
- **Port**: 8000
- **Purpose**: Main application API
- **Dependencies**: All other services

### UI (Frontend)
- **Port**: 80
- **Purpose**: React frontend application
- **Access**: Main entry point for users

## Configuration

### Secrets Management
Update `k8s-manifests/secret.yaml` with actual values:
```bash
# Generate base64 encoded secrets
echo -n "your-openai-api-key" | base64
# Update the secret.yaml file with the output
```

### Container Images
The manifests expect these images to be available:
- `ghcr.io/jimjrxieb/portfolio-chromadb:latest`
- `ghcr.io/jimjrxieb/portfolio-avatar-creation:latest`
- `ghcr.io/jimjrxieb/portfolio-rag-pipeline:latest`
- `ghcr.io/jimjrxieb/portfolio-api:latest`
- `ghcr.io/jimjrxieb/portfolio-ui:latest`

Build and push these images from your Portfolio repository.

## Workflow

1. **Code changes** in Portfolio repository
2. **CI/CD pipeline** builds and pushes container images
3. **ArgoCD** detects changes in k8s-manifests
4. **Automatic deployment** to local Kubernetes cluster

## Troubleshooting

### ArgoCD Issues
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Reset ArgoCD admin password
kubectl patch secret argocd-initial-admin-secret -n argocd -p '{"data":{"password":null}}'
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-server
```

### Portfolio Application Issues
```bash
# Check Portfolio application status
kubectl get all -n portfolio

# Check specific service logs
kubectl logs -n portfolio -l app.kubernetes.io/name=api

# Describe failing pods
kubectl describe pod -n portfolio -l app.kubernetes.io/name=chromadb
```

### ArgoCD Application Sync Issues
```bash
# Force sync Portfolio application
kubectl patch application portfolio -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Check application status
kubectl get application portfolio -n argocd -o yaml
```

## Next Steps

1. **Copy k8s-manifests** to Portfolio repository
2. **Build and push** container images
3. **Update secrets** with actual API keys
4. **Configure ingress** for custom domain (optional)
5. **Set up monitoring** with the monitoring-apps.yaml

## Security Notes

- The setup uses `--insecure` flag for ArgoCD (development only)
- Container images use `latest` tags (not recommended for production)
- Secrets are base64 encoded placeholders (update with real values)
- LoadBalancer service exposes services publicly (fine for local development)

For production deployment, review and implement proper security measures.