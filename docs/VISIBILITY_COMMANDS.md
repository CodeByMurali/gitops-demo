# OneView GitOps Visibility Commands

## Deployment Commands (3-Level Architecture)

### LEVEL 3: Deploy Everything (Root App)

```bash
# Switch to hub cluster
kubectl config use-context mrajendran@numerix.com@hub.us-east-1.eksctl.io

# Deploy root application (deploys all ApplicationSets)
kubectl apply -f root-argocd-app.yml

# This creates:
# - prod-account (4 production apps → Spoke1)
# - non-prod-account (6 apps: 3 dev + 3 qa → Spoke2)
# Total: 10 applications across 2 clusters

# Verify root app
kubectl get application oneview-all-apps -n argocd

# Check ApplicationSets created
kubectl get applicationset -n argocd
```

### LEVEL 2: Deploy Specific Environment (ApplicationSets)

```bash
# Deploy ONLY Production apps (Spoke1)
kubectl apply -f clusters/prod-account.yml

# This creates:
# - cross-asset-prod
# - fincad-prod
# - nx-core-prod
# - polypath-prod

# Verify production ApplicationSet
kubectl get applicationset prod-account -n argocd

# Check production apps created
kubectl get applications -n argocd | grep prod
```

```bash
# Deploy ONLY Dev & QA apps (Spoke2)
kubectl apply -f clusters/non-prod-account.yml

# This creates:
# DEV:
# - fincad-dev
# - kynex-dev
# - polypath-dev
# QA:
# - cross-asset-qa
# - fincad-qa
# - nx-core-qa

# Verify spoke2 ApplicationSet
kubectl get applicationset non-prod-account -n argocd

# Check dev apps created
kubectl get applications -n argocd | grep dev

# Check qa apps created
kubectl get applications -n argocd | grep qa
```

### LEVEL 1: Deploy Single App Directly (Bypass ArgoCD)

```bash
# Deploy single app using Kustomize (without ArgoCD)
# This bypasses GitOps - use only for testing!

# Deploy fincad to production manually
kubectl config use-context mrajendran@numerix.com@spoke1.us-east-1.eksctl.io
kubectl apply -k apps/fincad/envs/prod

# Deploy kynex to dev manually
kubectl config use-context mrajendran@numerix.com@spoke2.us-east-1.eksctl.io
kubectl apply -k apps/kynex/envs/dev

# Verify deployment
kubectl get all -n fincad-prod
kubectl get all -n kynex-dev
```

### Delete/Cleanup Commands

```bash
# Delete everything (LEVEL 3)
kubectl delete -f root-argocd-app.yml

# Delete specific environment (LEVEL 2)
kubectl delete -f clusters/prod-account.yml
kubectl delete -f clusters/non-prod-account.yml

# Delete single application
kubectl delete application cross-asset-prod -n argocd

# Delete ApplicationSet (removes all child apps)
kubectl delete applicationset prod-account -n argocd
kubectl delete applicationset non-prod-account -n argocd
```

### Deployment Verification

```bash
# After deploying, verify status

# Check root app
kubectl get application oneview-all-apps -n argocd

# Check ApplicationSets
kubectl get applicationset -n argocd

# Check all applications
kubectl get applications -n argocd

# Check sync status
argocd app list

# Watch deployment progress
watch kubectl get applications -n argocd
```

### Deployment Flow Summary

```
LEVEL 3 (Root App):
  kubectl apply -f root-argocd-app.yml
  ↓
  Deploys both ApplicationSets
  ↓
  ├─> Production AppSet → 4 apps to Spoke1
  └─> Spoke2 AppSet → 6 apps to Spoke2 (3 dev + 3 qa)

LEVEL 2 (ApplicationSets):
  kubectl apply -f clusters/prod-account.yml
  ↓
  Scans apps/*/envs/prod directories
  ↓
  Creates 4 applications on Spoke1

LEVEL 1 (Direct Kustomize):
  kubectl apply -k apps/fincad/envs/prod
  ↓
  Directly deploys to current cluster
  ↓
  No ArgoCD tracking (not recommended for production)
```

---

## Quick Reference Commands

### ArgoCD Application Status

```bash
# List all applications
kubectl get applications -n argocd

# List with sync status
kubectl get applications -n argocd -o wide

# Watch applications in real-time
watch kubectl get applications -n argocd
```

### Detailed Application Info

```bash
# Get specific application details
argocd app get cross-asset-prod
argocd app get fincad-prod
argocd app get nx-core-prod
argocd app get polypath-prod
argocd app get fincad-dev
argocd app get kynex-dev
argocd app get polypath-dev
argocd app get cross-asset-qa
argocd app get fincad-qa
argocd app get nx-core-qa

# Get all apps summary
argocd app list
```

### Cluster Context Commands

```bash
# Check current context
kubectl config current-context

# Switch to hub cluster
kubectl config use-context mrajendran@numerix.com@hub.us-east-1.eksctl.io

# Switch to spoke1 (Production)
kubectl config use-context mrajendran@numerix.com@spoke1.us-east-1.eksctl.io

# Switch to spoke2 (Dev & QA)
kubectl config use-context mrajendran@numerix.com@spoke2.us-east-1.eksctl.io

# List all contexts
kubectl config get-contexts
```

### Cluster Aliases (Set Once)

```bash
# Create aliases for easy switching
alias khub='kubectl --context=mrajendran@numerix.com@hub.us-east-1.eksctl.io'
alias k1='kubectl --context=mrajendran@numerix.com@spoke1.us-east-1.eksctl.io'
alias k2='kubectl --context=mrajendran@numerix.com@spoke2.us-east-1.eksctl.io'

# Usage
khub get applications -n argocd
k1 get pods --all-namespaces
k2 get pods --all-namespaces
```

### Check Pods on Spoke Clusters

```bash
# Production pods (Spoke1)
k1 get pods --all-namespaces
k1 get pods -n cross-asset-prod
k1 get pods -n fincad-prod
k1 get pods -n nx-core-prod
k1 get pods -n polypath-prod

# Dev & QA pods (Spoke2)
k2 get pods --all-namespaces
k2 get pods -n fincad-dev
k2 get pods -n kynex-dev
k2 get pods -n polypath-dev
k2 get pods -n cross-asset-qa
k2 get pods -n fincad-qa
k2 get pods -n nx-core-qa
```

### Check Services

```bash
# Production services (Spoke1)
k1 get svc -n cross-asset-prod
k1 get svc -n fincad-prod
k1 get svc -n nx-core-prod
k1 get svc -n polypath-prod

# Dev & QA services (Spoke2)
k2 get svc -n fincad-dev
k2 get svc -n kynex-dev
k2 get svc -n cross-asset-qa
k2 get svc -n fincad-qa
```

### Check Deployments

```bash
# Production deployments (Spoke1)
k1 get deployments --all-namespaces
k1 get deployment -n fincad-prod

# Dev & QA deployments (Spoke2)
k2 get deployments --all-namespaces
k2 get deployment -n fincad-dev
k2 get deployment -n cross-asset-qa
```

### ArgoCD Sync Status

```bash
# Check sync status of all apps
argocd app list -o wide

# Check if apps are healthy
argocd app list | grep -E "Healthy|Degraded"

# Check if apps are synced
argocd app list | grep -E "Synced|OutOfSync"
```

### Application Logs

```bash
# View application logs
argocd app logs cross-asset-prod
argocd app logs fincad-prod --tail 50
argocd app logs kynex-dev --follow

# View pod logs directly
k1 logs -n fincad-prod -l app=fincad
k2 logs -n kynex-dev -l app=kynex
```

### ArgoCD Health Check

```bash
# Check ArgoCD components
khub get pods -n argocd

# Check ArgoCD server status
khub get svc -n argocd

# Check registered clusters
argocd cluster list
```

### Resource Usage

```bash
# Check node resources on Spoke1
k1 top nodes
k1 top pods --all-namespaces

# Check node resources on Spoke2
k2 top nodes
k2 top pods --all-namespaces
```

### Namespace Overview

```bash
# List all namespaces on Spoke1
k1 get namespaces

# List all namespaces on Spoke2
k2 get namespaces

# Check resources in specific namespace
k2 get all -n kynex-dev
k2 get all -n cross-asset-qa
```

### Git Sync Status

```bash
# Check last sync time
argocd app get cross-asset-prod | grep "Last Sync"

# Check git revision
argocd app get fincad-prod | grep "Revision"

# Force refresh from Git
argocd app get fincad-prod --refresh
```

### Quick Health Dashboard

```bash
# One-liner to check all apps
argocd app list -o json | jq -r '.[] | "\(.metadata.name): \(.status.sync.status) / \(.status.health.status)"'

# Count apps by status
argocd app list -o json | jq -r '.[].status.health.status' | sort | uniq -c
```

### Troubleshooting Commands

```bash
# Check application events
khub get events -n argocd --sort-by='.lastTimestamp'

# Check ArgoCD application controller logs
khub logs -n argocd deployment/argocd-application-controller

# Check ArgoCD server logs
khub logs -n argocd deployment/argocd-server

# Describe application for details
kubectl describe application cross-asset-prod -n argocd
```

### Manual Sync Commands

```bash
# Sync specific application
argocd app sync cross-asset-prod

# Sync all production apps
argocd app sync -l env=prod

# Sync with prune (remove deleted resources)
argocd app sync fincad-prod --prune

# Hard refresh (ignore cache)
argocd app sync polypath-dev --force
```

### Access ArgoCD UI

```bash
# Port forward to ArgoCD UI
khub port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
khub get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

# Then open: https://localhost:8080
```

## Output Examples

### Example: List Applications
```
$ argocd app list
NAME                CLUSTER                        NAMESPACE           PROJECT  STATUS  HEALTH
cross-asset-prod    spoke1.us-east-1.eksctl.io     cross-asset-prod    default  Synced  Healthy
fincad-prod         spoke1.us-east-1.eksctl.io     fincad-prod         default  Synced  Healthy
nx-core-prod        spoke1.us-east-1.eksctl.io     nx-core-prod        default  Synced  Healthy
polypath-prod       spoke1.us-east-1.eksctl.io     polypath-prod       default  Synced  Healthy
fincad-dev          spoke2.us-east-1.eksctl.io     fincad-dev          default  Synced  Healthy
kynex-dev           spoke2.us-east-1.eksctl.io     kynex-dev           default  Synced  Healthy
polypath-dev        spoke2.us-east-1.eksctl.io     polypath-dev        default  Synced  Healthy
cross-asset-qa      spoke2.us-east-1.eksctl.io     cross-asset-qa      default  Synced  Healthy
fincad-qa           spoke2.us-east-1.eksctl.io     fincad-qa           default  Synced  Healthy
nx-core-qa          spoke2.us-east-1.eksctl.io     nx-core-qa          default  Synced  Healthyault  Synced  Healthy
kynex-non-prod      spoke2.us-east-1.eksctl.io     kynex-non-prod      default  Synced  Healthy
polypath-non-prod   spoke2.us-east-1.eksctl.io     polypath-non-prod   default  Synced  Healthy
```

### Example: Get Pods
```
$ k1 get pods --all-namespaces
NAMESPACE           NAME                                    READY   STATUS    RESTARTS   AGE
cross-asset-prod    cross-asset-deployment-7d8f9c-xyz       1/1     Running   0          2h
fincad-prod         fincad-deployment-5b6c8d-abc            1/1     Running   0          2h
nx-core-prod        nx-core-deployment-9f4e2a-def           1/1     Running   0          2h
polypath-prod       polypath-deployment-3a7b5c-ghi          1/1     Running   0          2h
```

### Example: Application Details
```
$ argocd app get fincad-prod
Name:               fincad-prod
Project:            default
Server:             spoke1.us-east-1.eksctl.io
Namespace:          fincad-prod
URL:                https://argocd.example.com/applications/fincad-prod
Repo:               https://github.com/CodeByMurali/gitops-demo.git
Target:             HEAD
Path:               apps/fincad/envs/prod
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to HEAD (abc1234)
Health Status:      Healthy
```

## Monitoring Dashboard Script

Save this as `check-oneview.sh`:

```bash
#!/bin/bash
echo "=== OneView GitOps Status ==="
echo ""
echo "Hub Cluster:"
kubectl --context=mrajendran@numerix.com@hub.us-east-1.eksctl.io get pods -n argocd
echo ""
echo "Applications:"
argocd app list
echo ""
echo "Spoke1 (Production) Pods:"
kubectl --context=mrajendran@numerix.com@spoke1.us-east-1.eksctl.io get pods --all-namespaces | grep -E "cross-asset|fincad|nx-core|polypath"
echo ""
echo "Spoke2 (Non-Prod) Pods:"
kubectl --context=mrajendran@numerix.com@spoke2.us-east-1.eksctl.io get pods --all-namespaces | grep -E "fincad|kynex|polypath"
```

Run with: `bash check-oneview.sh`
