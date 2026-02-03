# ArgoCD Setup Guide

## Prerequisites
- ArgoCD installed on your hub cluster
- kubectl configured to access your cluster
- GitHub account

## Step 1: Push to GitHub

```bash
cd C:\Users\MuraliRajendran\workspace\argocd\gitops-demo

# Initialize git
git init
git add .
git commit -m "Initial commit: OneView GitOps"

# Create a new repo on GitHub, then:
git remote add origin https://github.com/CodeByMurali/gitops-demo.git
git branch -M main
git push -u origin main
```

## Step 2: Update Repository URLs

Replace `YOUR_USERNAME` with your actual GitHub username in these files:
- `root-argocd-app.yml`
- `appsets/my-prod-appset.yml`
- `appsets/my-qa-appset.yml`
- `appsets/my-staging-appset.yml`

## Step 3: Deploy to ArgoCD

### Option A: Deploy All Environments (Prod, QA, Staging)

```bash
kubectl apply -f root-argocd-app.yml
```

This creates:
- **Prod apps**: cross-asset-prod-us, cross-asset-prod-eu, fincad-prod-us, fincad-prod-eu, nx-core-prod-us, nx-core-prod-eu, polypath-prod-us
- **QA apps**: fincad-qa, kynex-qa, polypath-qa
- **Staging apps**: fincad-staging, polypath-staging

### Option B: Deploy Specific Environment

```bash
# Only production
kubectl apply -f appsets/my-prod-appset.yml

# Only QA
kubectl apply -f appsets/my-qa-appset.yml

# Only staging
kubectl apply -f appsets/my-staging-appset.yml
```

## Step 4: Verify Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Open browser: https://localhost:8080
- Username: `admin`
- Password: (from command above)

## Apps Deployed by Environment

| App | prod-us | prod-eu | qa | staging |
|-----|---------|---------|----|---------| 
| cross-asset | ✅ | ✅ | ❌ | ❌ |
| fincad | ✅ | ✅ | ✅ | ✅ |
| kynex | ❌ | ❌ | ✅ | ❌ |
| nx-core | ✅ | ✅ | ❌ | ❌ |
| polypath | ✅ | ❌ | ✅ | ✅ |

## GitOps Workflow

1. Make changes to manifests in `apps/` folder
2. Commit and push to GitHub
3. ArgoCD automatically syncs changes (automated sync enabled)
4. Manual changes in cluster are reverted (selfHeal enabled)

## Troubleshooting

```bash
# Check app status
argocd app get <app-name>

# Sync manually
argocd app sync <app-name>

# View logs
kubectl logs -n argocd deployment/argocd-application-controller
```
