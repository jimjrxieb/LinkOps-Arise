#!/bin/bash
set -e

AKS_RG="linkops-rg"
AKS_NAME="linkops-aks"

echo "🔑 Getting AKS credentials..."
az aks get-credentials --resource-group $AKS_RG --name $AKS_NAME --overwrite-existing

echo "📦 Adding Helm repos..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add kubeflow-pipelines https://kubeflow.github.io/pipelines
helm repo update

echo "🚀 Installing ArgoCD..."
helm install argocd argo/argo-cd --namespace argocd --create-namespace

echo "📈 Installing Prometheus..."
helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace

echo "📊 Installing Grafana..."
helm install grafana grafana/grafana --namespace monitoring

echo "🧪 Installing Kubeflow Pipelines..."
helm install kfp kubeflow-pipelines/kubeflow-pipelines --namespace kubeflow --create-namespace

echo "✅ All services deployed to AKS."
echo ""
echo "🔧 Optional: Test Kubeflow Pipelines locally:"
echo "kubectl get pods -n kubeflow"
echo "kubectl port-forward svc/ml-pipeline-ui -n kubeflow 8081:80"
echo "Then open: http://localhost:8081" 