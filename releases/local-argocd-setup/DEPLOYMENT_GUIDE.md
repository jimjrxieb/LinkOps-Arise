# Portfolio Local Deployment Guide

## Step-by-Step Deployment

### Phase 1: ArgoCD Setup (5 minutes)

1. **Ensure Docker Desktop Kubernetes is running**
   ```bash
   kubectl cluster-info --context docker-desktop
   ```

2. **Deploy ArgoCD**
   ```bash
   cd /path/to/LinkOps-Arise/releases/local-argocd-setup
   ./scripts/deploy-local.sh
   ```

3. **Access ArgoCD UI**
   - The script will display the admin password
   - Run: `/tmp/argocd-port-forward.sh`
   - Open: https://localhost:8080
   - Login: admin / [displayed password]

### Phase 2: Portfolio Repository Setup

1. **Copy k8s manifests to Portfolio repository**
   ```bash
   cp -r k8s-manifests/portfolio /path/to/Portfolio/k8s-manifests
   ```

2. **Build and push container images**
   ```bash
   cd /path/to/Portfolio

   # Build all images
   docker build -t ghcr.io/jimjrxieb/portfolio-ui:latest ./ui
   docker build -t ghcr.io/jimjrxieb/portfolio-api:latest ./api
   docker build -t ghcr.io/jimjrxieb/portfolio-chromadb:latest ./chromadb
   docker build -t ghcr.io/jimjrxieb/portfolio-avatar-creation:latest ./avatar-creation
   docker build -t ghcr.io/jimjrxieb/portfolio-rag-pipeline:latest ./rag-pipeline

   # Push to GitHub Container Registry
   docker push ghcr.io/jimjrxieb/portfolio-ui:latest
   docker push ghcr.io/jimjrxieb/portfolio-api:latest
   docker push ghcr.io/jimjrxieb/portfolio-chromadb:latest
   docker push ghcr.io/jimjrxieb/portfolio-avatar-creation:latest
   docker push ghcr.io/jimjrxieb/portfolio-rag-pipeline:latest
   ```

3. **Update secrets with real values**
   ```bash
   cd /path/to/Portfolio/k8s-manifests

   # Generate OpenAI API key secret
   echo -n "your-actual-openai-api-key" | base64

   # Edit secret.yaml and replace the placeholder
   vim secret.yaml
   ```

### Phase 3: Deploy Portfolio Application

1. **Apply Portfolio ArgoCD application**
   ```bash
   cd /path/to/LinkOps-Arise/releases/local-argocd-setup
   kubectl apply -f argocd-apps/portfolio-app.yaml
   ```

2. **Monitor deployment in ArgoCD UI**
   - Go to https://localhost:8080
   - Click on "portfolio" application
   - Watch the sync process

3. **Check application status**
   ```bash
   # Check all portfolio resources
   kubectl get all -n portfolio

   # Check pod status
   kubectl get pods -n portfolio -w
   ```

### Phase 4: Access Application

1. **Check LoadBalancer service**
   ```bash
   kubectl get svc portfolio-loadbalancer -n portfolio
   ```

2. **Access via LoadBalancer**
   - Wait for EXTERNAL-IP to be assigned
   - Open browser to the external IP

3. **Alternative: Port Forward**
   ```bash
   kubectl port-forward svc/ui -n portfolio 3000:80
   # Access at http://localhost:3000
   ```

## Service Access Points

Once deployed, you can access services at:

- **Portfolio UI**: http://localhost (via LoadBalancer) or http://localhost:3000 (port-forward)
- **API**: http://localhost/api or http://localhost:8000 (port-forward)
- **Jupyter Lab**: http://localhost/jupyter or http://localhost:8888 (port-forward)
- **ArgoCD UI**: https://localhost:8080

## Monitoring Deployment

### ArgoCD Application Status
```bash
# List all ArgoCD applications
kubectl get applications -n argocd

# Describe specific application
kubectl describe application portfolio -n argocd

# Get application logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Portfolio Services Health
```bash
# Check all services
kubectl get pods,svc,ingress -n portfolio

# Check specific service logs
kubectl logs -n portfolio -l app.kubernetes.io/name=ui
kubectl logs -n portfolio -l app.kubernetes.io/name=api
kubectl logs -n portfolio -l app.kubernetes.io/name=chromadb
```

## Common Issues and Solutions

### 1. ArgoCD Sync Failed
**Problem**: Application shows "OutOfSync" or "Failed" status

**Solution**:
```bash
# Check application events
kubectl describe application portfolio -n argocd

# Manual sync
kubectl patch application portfolio -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
kubectl patch application portfolio -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### 2. Container Image Pull Errors
**Problem**: Pods stuck in `ImagePullBackOff`

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n portfolio

# Verify images exist
docker pull ghcr.io/jimjrxieb/portfolio-ui:latest

# Update image tags in manifests if needed
```

### 3. Service Connection Issues
**Problem**: Services can't communicate with each other

**Solution**:
```bash
# Check service discovery
kubectl get svc -n portfolio
kubectl get endpoints -n portfolio

# Test connectivity from pod
kubectl exec -it <pod-name> -n portfolio -- curl http://chromadb:8000/api/v1/heartbeat
```

### 4. LoadBalancer Not Getting External IP
**Problem**: LoadBalancer service shows `<pending>` for EXTERNAL-IP

**Solution** (Docker Desktop specific):
```bash
# Check if LoadBalancer is supported
kubectl get nodes -o wide

# Use port-forward as alternative
kubectl port-forward svc/portfolio-loadbalancer -n portfolio 80:80
```

## Cleanup

### Remove Portfolio Application
```bash
# Delete ArgoCD application
kubectl delete application portfolio -n argocd

# Delete namespace (if needed)
kubectl delete namespace portfolio
```

### Remove ArgoCD
```bash
# Uninstall ArgoCD
helm uninstall argocd -n argocd

# Delete namespace
kubectl delete namespace argocd
```

## Next Steps

1. **Set up CI/CD pipeline** to automatically build and push images
2. **Configure ingress** with proper domain names
3. **Add monitoring** with Prometheus and Grafana
4. **Implement security scanning** for container images
5. **Set up staging environment** in cloud provider

## Support

If you encounter issues:
1. Check the troubleshooting section in README.md
2. Review ArgoCD and Kubernetes logs
3. Verify all prerequisites are met
4. Check container image availability