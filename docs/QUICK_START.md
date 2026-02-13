# Quick Start - ArgoCD Multi-Cluster Setup

## 🚀 Step 1: Create EKS Clusters

```bash
# CD into script dir
cd <repoRoot>

# Create hub and spoke clusters
./scripts/02_cluster_setup.sh

# When prompted:
# - Number of spoke clusters: 2
# - Hub cluster name: hub
# - Region: us-east-1
# - Node type: t3.medium (default)
# - Nodes per cluster: 2 (default)
```

---

## ⚙️ Step 2: Install ArgoCD on Hub Cluster

```bash
kubectl config get-contexts


# Switch to hub cluster context
kubectl config use-context <Username>@numerix.com@hub.us-east-1.eksctl.io

# Install ArgoCD
./scripts/03_argocd_installtion.sh

# Add these aliases to your shell profile
alias khub='kubectl --context=<Username>@numerix.com@hub.us-east-1.eksctl.io'
alias k1='kubectl --context=<Username>@numerix.com@spoke1.us-east-1.eksctl.io'
alias k2='kubectl --context=<Username>@numerix.com@spoke2.us-east-1.eksctl.io'
```

---

### 🔗 Step 3: Register Spoke Clusters

> **⚠️ Important:** Must be done before deploying applications

```bash
# Register clusters and repo with ArgoCD (automated script)
#Get password
khub -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

#In a seperate terminal with AWS creds SSO login
khub port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI (get password from step 4)
argocd login localhost:8080 --username admin --password <admin-password> --insecure


./scripts/06_argocd_cluster_repo_reg.sh

## Manual steps (Ignore if 06_argocd_cluster_repo_reg.sh executes successfult)
# Login to ArgoCD CLI (get password from step 4)
argocd login localhost:8080 --username admin --password <admin-password> --insecure

# Register Production Spoke1
argocd cluster add <Username>@numerix.com@spoke1.us-east-1.eksctl.io --name spoke1.us-east-1.eksctl.io --upsert

# Register Dev/QA Spoke2
argocd cluster add <Username>@numerix.com@spoke2.us-east-1.eksctl.io --name spoke2.us-east-1.eksctl.io --upsert

# Add repositories to ArgoCD
argocd repo add https://github.com/<app-props-repo>
argocd repo add https://github.com/<davinci-props-repo>

# Verify clusters and repos registered
argocd cluster list
argocd repo list
```

---

## 🌐 Step 4: Access ArgoCD UI

### Get Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
```

### 🔥 Option A: Port Forward (Recommended)
```bash
# In a separate terminal
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser
cmd.exe /c start https://localhost:8080
```

### 🌍 Option B: NodePort Service
```bash
# Change service to NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'

# Get NodePort
kubectl get svc argocd-server -n argocd

# Get node external IP
kubectl get nodes -o wide

# Access: https://<node-external-ip>:<nodeport>
```

### ☁️ Option C: LoadBalancer (AWS)
```bash
# Change to LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Get external IP (takes 2-3 minutes)
kubectl get svc argocd-server -n argocd

# Access: https://<external-ip>
```

**Login Credentials:**
- Username: `admin`
- Password: (from step above)

---

## 📦 Step 5: Deploy ApplicationSets

### ⚡ Set Up Cluster Aliases (Recommended)
```bash
# Add these aliases to your shell profile
alias khub='kubectl --context=<Username>@numerix.com@hub.us-east-1.eksctl.io'
alias k1='kubectl --context=<Username>@numerix.com@spoke1.us-east-1.eksctl.io'
alias k2='kubectl --context=<Username>@numerix.com@spoke2.us-east-1.eksctl.io' # Only if you choose to create 2nd spoke

# Usage examples
khub get pods -n argocd
k1 get nodes
k2 get nodes
```


### 📋 Key ArgoCD Commands
```bash
# List all applications
argocd app list

# List all applicationsets
khub get applicationsets -n argocd

# Get applicationset details
khub describe applicationset <appset-name> -n argocd

# Sync an application
argocd app sync <app-name>

# Get application status
argocd app get <app-name>

# List registered clusters
argocd cluster list
```

### 🔍 ArgoCD Status Check Commands
```bash
# 5. Login to ArgoCD CLI (if needed)
argocd login localhost:8080 --username admin --password <admin-password> --insecure

# 1. Check if ArgoCD CLI is connected
argocd cluster list

# 2. Check if you're logged in
argocd account get-user-info

# 3. Check applications via kubectl
khub get applications -n argocd

# 4. Check applicationsets
khub get applicationsets -n argocd
```

### 🚀 Deploy ApplicationSets

#### IMPORTANT: Push Changes to GitHub First

**ArgoCD pulls application manifests from GitHub, not local files!**

```bash
# Navigate to CDUsingArgoCD repo
cd <app-props-repo>

# Check status
git status

# Add and commit changes
git add .
git commit -m "Update application manifests"

# Push to GitHub (sep-custom-folder branch)
git push origin sep-custom-folder
```

#### Deploy Kynex (Pooled Applications)

**Deploy Kynex dev and prod:**
```bash
# Kynex dev (deploys to spoke2)
khub apply -f <davinci-props-repo>/kynex/nonprod/dev/argocd/

# Kynex prod (deploys to spoke1)
khub apply -f <davinci-props-repo>/kynex/prod/prod/argocd/
```

#### Deploy OneView - Jefferies

**Deploy Jefferies dev and prod:**
```bash
# Jefferies dev (deploys to spoke2)
khub apply -f <davinci-props-repo>/oneview/nonprod/jefferies/dev/argocd/

# Jefferies prod (deploys to spoke1)
khub apply -f <davinci-props-repo>/oneview/prod/jeffries/prod/argocd/
```

#### Deploy OneView - OCBC

**Deploy OCBC dev and prod:**
```bash
# OCBC dev (deploys to spoke2)
khub apply -f <davinci-props-repo>/oneview/nonprod/ocbc/dev/argocd/

# OCBC prod (deploys to spoke1)
khub apply -f <davinci-props-repo>/oneview/prod/ocbc/prod/argocd/
```

#### Deploy All at Once

**Deploy everything:**
```bash
# Deploy all Kynex
khub apply -f <davinci-props-repo>/kynex/nonprod/dev/argocd/
khub apply -f <davinci-props-repo>/kynex/prod/prod/argocd/

# Deploy all Jefferies
khub apply -f <davinci-props-repo>/oneview/nonprod/jefferies/dev/argocd/
khub apply -f <davinci-props-repo>/oneview/prod/jeffries/prod/argocd/

# Deploy all OCBC
khub apply -f <davinci-props-repo>/oneview/nonprod/ocbc/dev/argocd/
khub apply -f <davinci-props-repo>/oneview/prod/ocbc/prod/argocd/
```

#### Verify Deployments
```bash
# List all applications
argocd app list

# List all applicationsets
khub get applicationsets -n argocd

# List all appprojects
khub get appprojects -n argocd

# Watch application sync status
khub get applications -n argocd -w

# Check specific application
argocd app get <app-name>

# Check ApplicationSet controller logs
khub logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=50
```


---

## 🗑️ Application Deletion

### Delete Applications and ApplicationSets

#### Delete All Applications and Clean Up

**Delete everything:**
```bash
# Delete all applications
argocd app delete $(argocd app list -o name) --yes

# Delete all applicationsets
khub delete applicationsets --all -n argocd

# Delete all appprojects (except default)
khub get appprojects -n argocd --no-headers | grep -v default | awk '{print $1}' | xargs -I {} khub delete appproject {} -n argocd

# Clean up orphaned resources on spoke clusters
k1 delete all --all -n dev
k1 delete all --all -n prod
k2 delete all --all -n dev
k2 delete all --all -n prod
```

#### Delete Specific Client ApplicationSet

**Delete specific client appsets:**
```bash
# Delete Kynex
khub delete -f <davinci-props-repo>/kynex/nonprod/dev/argocd/
khub delete -f <davinci-props-repo>/kynex/prod/prod/argocd/

# Delete Jefferies
khub delete -f <davinci-props-repo>/oneview/nonprod/jefferies/dev/argocd/
khub delete -f <davinci-props-repo>/oneview/prod/jeffries/prod/argocd/

# Delete OCBC
khub delete -f <davinci-props-repo>/oneview/nonprod/ocbc/dev/argocd/
khub delete -f <davinci-props-repo>/oneview/prod/ocbc/prod/argocd/
```

#### Delete Individual Applications via ArgoCD CLI

**Delete specific application:**
```bash
# Delete a single application
argocd app delete <app-name>

# Delete with cascade (removes k8s resources)
argocd app delete <app-name> --cascade

# Delete without confirmation prompt
argocd app delete <app-name> --yes

# Delete multiple applications
argocd app delete app1 app2 app3 --yes
```

#### Delete ApplicationSets via kubectl

**Delete applicationset (will delete all child applications):**
```bash
# Delete specific applicationset
khub delete applicationset <appset-name> -n argocd

# List all applicationsets first
khub get applicationsets -n argocd

# Delete applicationset example (use actual appset names)
khub delete applicationset jefferies-prod -n argocd
khub delete applicationset ocbc-dev -n argocd
```

#### Verify Deletion
```bash
# Check remaining applications
argocd app list
khub get applications -n argocd

# Check remaining applicationsets
khub get applicationsets -n argocd

# Check if resources are cleaned up from target clusters
k1 get all -A
k2 get all -A
```

#### Force Delete Stuck Applications

**If applications are stuck in deletion:**
```bash
# Remove finalizers from application
khub patch application <app-name> -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge

# Force delete application
khub delete application <app-name> -n argocd --force --grace-period=0

# Remove finalizers from applicationset
khub patch applicationset <appset-name> -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
```

---

## 🗑️ Cluster Management

### 💰 Scale Down Clusters (Cost Optimization)
```bash
# First, find the actual nodegroup names
eksctl get nodegroup --cluster=hub --region=us-east-1
eksctl get nodegroup --cluster=spoke1 --region=us-east-1
eksctl get nodegroup --cluster=spoke2 --region=us-east-1
eksctl get nodegroup --cluster=spoke1 --region=us-east-1
eksctl get nodegroup --cluster=spoke2 --region=us-east-1

# If you have multiple nodegroups, delete old ones first
# eksctl delete nodegroup --cluster=hub --name=<old-nodegroup> --region=us-east-1

# Scale down using the actual nodegroup names (replace <nodegroup-name>)
# Hub cluster
eksctl scale nodegroup --cluster=hub --name=<nodegroup-name> --nodes=1 --nodes-min=1 --nodes-max=1 --region=us-east-1

# Spoke clusters
eksctl scale nodegroup --cluster=spoke1 --name=<nodegroup-name> --nodes=1 --nodes-min=1 --nodes-max=1 --region=us-east-1
eksctl scale nodegroup --cluster=spoke2 --name=<nodegroup-name> --nodes=1 --nodes-min=1 --nodes-max=1 --region=us-east-1

#Example
eksctl scale nodegroup --cluster=hub --name=ng-934a25e4 --nodes=1 --nodes-min=0 --nodes-max=1 --region=us-east-1
eksctl scale nodegroup --cluster=spoke1 --name=ng-eecdca52 --nodes=1 --nodes-min=0 --nodes-max=1 --region=us-east-1
eksctl scale nodegroup --cluster=spoke2 --name=ng-3c8b1441 --nodes=1 --nodes-min=0 --nodes-max=1 --region=us-east-1

# Verify scaling
kubectl get nodes
```

### 🤖 Automated Deletion Script
```bash
# Use the existing deletion script
./scripts/04_cluster_deletion.sh
```

### 🔨 Manual Deletion Steps
```bash
# Delete hub cluster
eksctl delete cluster --name hub --region us-east-1

# Delete spoke clusters
eksctl delete cluster --name spoke1 --region us-east-1
eksctl delete cluster --name spoke2 --region us-east-1

# Verify deletion
eksctl get clusters --region us-east-1
```

---

## 🛠️ Troubleshooting

### ❌ ArgoCD pods pending/crashing?
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check pod resources
kubectl get pods -n argocd
kubectl describe pod <pod-name> -n argocd
```

### 🌐 Can't access ArgoCD UI?
```bash
# Check service
kubectl get svc argocd-server -n argocd

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 🔑 Forgot admin password?
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
```

---

## 📝 Manual EKS Commands (Alternative)

> Instead of using the creation script, you can manually run these commands. Add the `--profile` flag if you have multiple AWS CLI profiles configured.

### 🏗️ EKS Clusters Creation
```bash
eksctl create cluster --name hub-cluster --region us-east-1
eksctl create cluster --name spoke-cluster-1 --region us-east-1
eksctl create cluster --name spoke-cluster-2 --region us-east-1
```

### 🗑️ EKS Cluster Deletion
```bash
eksctl delete cluster --name hub-cluster --region us-east-1
eksctl delete cluster --name spoke-cluster-1 --region us-east-1
eksctl delete cluster --name spoke-cluster-2 --region us-east-1
```

