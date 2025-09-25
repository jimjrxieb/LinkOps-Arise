# Quick Command Reference

## One-Time Setup
```bash
# 1. Deploy ArgoCD
./scripts/deploy-local.sh

# 2. Start ArgoCD UI port-forward
/tmp/argocd-port-forward.sh &

# 3. Deploy Portfolio application
kubectl apply -f argocd-apps/portfolio-app.yaml
```

## Daily Development Workflow
```bash
# Check application status
kubectl get applications -n argocd
kubectl get pods -n portfolio

# Access services
kubectl port-forward svc/ui -n portfolio 3000:80 &
kubectl port-forward svc/api -n portfolio 8000:8000 &

# View logs
kubectl logs -n portfolio -l app.kubernetes.io/name=api -f
```

## ArgoCD Management
```bash
# Login to ArgoCD CLI
argocd login localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure

# List applications
argocd app list

# Sync application
argocd app sync portfolio

# Get application details
argocd app get portfolio
```

## Kubernetes Debugging
```bash
# Check all resources
kubectl get all -A

# Describe failing pod
kubectl describe pod <pod-name> -n portfolio

# Check events
kubectl get events -n portfolio --sort-by=.metadata.creationTimestamp

# Execute into pod
kubectl exec -it <pod-name> -n portfolio -- /bin/bash

# Check logs with timestamps
kubectl logs -n portfolio <pod-name> --timestamps=true
```

## Service Testing
```bash
# Test ChromaDB
kubectl port-forward svc/chromadb -n portfolio 8001:8000 &
curl http://localhost:8001/api/v1/heartbeat

# Test API
kubectl port-forward svc/api -n portfolio 8000:8000 &
curl http://localhost:8000/health

# Test UI
kubectl port-forward svc/ui -n portfolio 3000:80 &
curl http://localhost:3000
```

## Container Management
```bash
# Build all images (from Portfolio repo)
docker build -t ghcr.io/jimjrxieb/portfolio-ui:latest ./ui
docker build -t ghcr.io/jimjrxieb/portfolio-api:latest ./api
docker build -t ghcr.io/jimjrxieb/portfolio-chromadb:latest ./chromadb
docker build -t ghcr.io/jimjrxieb/portfolio-avatar-creation:latest ./avatar-creation
docker build -t ghcr.io/jimjrxieb/portfolio-rag-pipeline:latest ./rag-pipeline

# Push all images
docker push ghcr.io/jimjrxieb/portfolio-ui:latest
docker push ghcr.io/jimjrxieb/portfolio-api:latest
docker push ghcr.io/jimjrxieb/portfolio-chromadb:latest
docker push ghcr.io/jimjrxieb/portfolio-avatar-creation:latest
docker push ghcr.io/jimjrxieb/portfolio-rag-pipeline:latest
```

## Secret Management
```bash
# Update OpenAI API key
kubectl create secret generic portfolio-secrets \
  --from-literal=OPENAI_API_KEY=your-actual-api-key \
  -n portfolio --dry-run=client -o yaml | kubectl apply -f -

# Check current secrets
kubectl get secret portfolio-secrets -n portfolio -o yaml

# Decode secret
kubectl get secret portfolio-secrets -n portfolio -o jsonpath="{.data.OPENAI_API_KEY}" | base64 -d
```

## Cleanup Commands
```bash
# Delete Portfolio application
kubectl delete application portfolio -n argocd

# Delete Portfolio namespace
kubectl delete namespace portfolio

# Uninstall ArgoCD
helm uninstall argocd -n argocd
kubectl delete namespace argocd

# Stop all port-forwards
pkill -f "kubectl port-forward"
```

## Monitoring Commands
```bash
# Watch pods status
kubectl get pods -n portfolio -w

# Monitor resource usage
kubectl top pods -n portfolio
kubectl top nodes

# Check persistent volumes
kubectl get pv,pvc -n portfolio

# Check ingress
kubectl get ingress -n portfolio
kubectl describe ingress portfolio-ingress -n portfolio
```

## Troubleshooting One-Liners
```bash
# Restart all deployments
kubectl rollout restart deployment -n portfolio

# Check pod resource limits
kubectl describe pods -n portfolio | grep -A 5 -B 5 "Limits\|Requests"

# Find failing pods
kubectl get pods -A --field-selector=status.phase!=Running

# Check image pull status
kubectl get pods -n portfolio -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].state}{"\n"}{end}'

# Force delete stuck pods
kubectl delete pod <pod-name> -n portfolio --force --grace-period=0
```