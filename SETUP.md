# ArgoCD Multi-Cluster Setup Guide

## Your Cluster Setup
- **Hub**: hub.us-east-1.eksctl.io (ArgoCD runs here)
- **Spoke1**: spoke1.us-east-1.eksctl.io (Production apps)
- **Spoke2**: spoke2.us-east-1.eksctl.io (QA apps)

## Prerequisites
- ArgoCD installed on hub cluster
- kubectl configured with all cluster contexts
- GitHub repo: https://github.com/CodeByMurali/gitops-demo

## Step 1: Add Spoke Clusters to ArgoCD

```bash
# Switch to hub cluster
kubectl config use-context mrajendran@numerix.com@hub.us-east-1.eksctl.io

# Add spoke1 (Production)
argocd cluster add mrajendran@numerix.com@spoke1.us-east-1.eksctl.io --name spoke1.us-east-1.eksctl.io

# Add spoke2 (QA)
argocd cluster add mrajendran@numerix.com@spoke2.us-east-1.eksctl.io --name spoke2.us-east-1.eksctl.io

# Verify clusters
argocd cluster list
```

## Step 2: Deploy Applications

```bash
# Deploy all apps to both clusters
kubectl apply -f root-argocd-app.yml
```

## What Gets Deployed

### Spoke1 (Production):
- cross-asset-prod
- fincad-prod
- nx-core-prod
- polypath-prod

### Spoke2 (QA):
- fincad-qa
- kynex-qa
- polypath-qa

## Step 3: Verify Deployment

```bash
# Check apps in ArgoCD
kubectl get applications -n argocd

# Check apps on spoke1
kubectl config use-context mrajendran@numerix.com@spoke1.us-east-1.eksctl.io
kubectl get pods --all-namespaces

# Check apps on spoke2
kubectl config use-context mrajendran@numerix.com@spoke2.us-east-1.eksctl.io
kubectl get pods --all-namespaces
```

## Alternative: Deploy Specific Environment

```bash
# Only production apps (spoke1)
kubectl apply -f appsets/oneview-prod-appset.yml

# Only QA apps (spoke2)
kubectl apply -f appsets/onview-qa-appset.yml
```

## Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Open: https://localhost:8080

## GitOps Workflow

1. Make changes to manifests in `apps/` folder
2. Commit and push to GitHub
3. ArgoCD automatically syncs changes
4. Manual cluster changes are reverted (selfHeal enabled)
