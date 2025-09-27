#!/bin/bash
# User data script for CKS learning EC2 instance

set -e

# Update system
yum update -y

# Install essential tools
yum install -y \
    docker \
    git \
    curl \
    wget \
    unzip \
    jq \
    vim

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install awscli v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip
unzip terraform_1.6.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Create working directory
mkdir -p /home/ec2-user/cks-practice
chown ec2-user:ec2-user /home/ec2-user/cks-practice

# Create helpful aliases
cat >> /home/ec2-user/.bashrc << 'EOF'
# CKS Learning aliases
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'

# Terraform aliases
alias tf='terraform'
alias tfa='terraform apply'
alias tfp='terraform plan'
alias tfd='terraform destroy'

# Export useful variables
export KUBE_EDITOR=vim
export PROJECT_NAME="${project_name}"
export ENVIRONMENT="${environment}"
EOF

# Install k9s for better cluster management
wget https://github.com/derailed/k9s/releases/download/v0.28.2/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/

# Install kubectx and kubens
git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Create sample CKS practice files
cat > /home/ec2-user/cks-practice/README.md << 'EOF'
# CKS Practice Environment

This EC2 instance is set up for CKS (Certified Kubernetes Security Specialist) practice.

## Installed Tools
- kubectl
- helm
- awscli
- terraform
- docker
- k9s
- kubectx/kubens

## Useful Commands
```bash
# Connect to EKS cluster
aws eks update-kubeconfig --region us-east-1 --name linkops-arise-sandbox-eks

# Check cluster status
kubectl cluster-info
kubectl get nodes

# Access cluster with k9s
k9s

# Check security policies
kubectl get psp  # Pod Security Policies (deprecated)
kubectl get networkpolicies --all-namespaces

# Check OPA Gatekeeper
kubectl get constraints
kubectl get constrainttemplates
```

## CKS Topics Covered
1. ✅ Pod Security Standards (Restricted, Baseline, Privileged)
2. ✅ Network Policies
3. ✅ OPA Gatekeeper Policies
4. ✅ Falco Runtime Security
5. ✅ External Secrets Management
6. ✅ TLS Certificate Management
EOF

chown -R ec2-user:ec2-user /home/ec2-user/cks-practice

# Log completion
echo "$(date): CKS learning environment setup complete" >> /var/log/user-data.log