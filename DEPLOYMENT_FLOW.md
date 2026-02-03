# OneView Microservices Deployment Flow

## Overview
OneView is a multi-microservice application deployed across multiple Kubernetes clusters using ArgoCD and GitOps principles.

---

## Architecture Diagram

```

```
                    ┌─────────────────────────────────┐
                    │      Hub Cluster                │
                    │  hub.us-east-1.eksctl.io        │
                    │                                 │
                    │  ┌──────────────────────────┐   │
                    │  │      ArgoCD              │   │
                    │  │  (Control Plane)         │   │
                    │  └──────────────────────────┘   │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
    ┌───────────────────────────┐   ┌───────────────────────────┐
    │   Spoke1 Cluster          │   │   Spoke2 Cluster          │
    │ spoke1.us-east-1.eksctl.io│   │ spoke2.us-east-1.eksctl.io│
    │                           │   │                           │
    │   PRODUCTION              │   │   NON-PROD                │
    ├───────────────────────────┤   ├───────────────────────────┤
    │                           │   │                           │
    │  • cross-asset-prod       │   │  • fincad-non-prod        │
    │  • fincad-prod            │   │  • kynex-non-prod         │
    │  • nx-core-prod           │   │  • polypath-non-prod      │
    │  • polypath-prod          │   │                           │
    │                           │   │                           │
    │  Total: 4 apps            │   │  Total: 3 apps            │
    └───────────────────────────┘   └───────────────────────────┘
```

┌─────────────────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                                   │
│                              gitops-demo                                     │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  root-argocd-app.yml (App-of-Apps)                                 │    │
│  │  └─> Points to: appsets/                                           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│                                    ▼                                         │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  ApplicationSets (appsets/)                                        │    │
│  │  ├─> oneview-prod-appset.yml  (Production)                         │    │
│  │  └─> onview-qa-appset.yml     (QA)                                 │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│                                    ▼                                         │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  Microservices (apps/)                                             │    │
│  │  ├─> cross-asset/                                                  │    │
│  │  ├─> fincad/                                                       │    │
│  │  ├─> kynex/                                                        │    │
│  │  ├─> nx-core/                                                      │    │
│  │  └─> polypath/                                                     │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ GitOps Sync
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Hub Cluster (ArgoCD)                                 │
│                  mrajendran@numerix.com@hub.us-east-1.eksctl.io             │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    ArgoCD Control Plane                            │    │
│  │                                                                     │    │
│  │  ┌──────────────────────────────────────────────────────────┐     │    │
│  │  │  Root Application: oneview-all-apps                      │     │    │
│  │  │  - Monitors: appsets/ directory                          │     │    │
│  │  │  - Auto-creates ApplicationSets                          │     │    │
│  │  └──────────────────────────────────────────────────────────┘     │    │
│  │                              │                                     │    │
│  │                 ┌────────────┴────────────┐                       │    │
│  │                 ▼                         ▼                       │    │
│  │  ┌──────────────────────┐    ┌──────────────────────┐           │    │
│  │  │ oneview-prod-appset  │    │ oneview-qa-appset    │           │    │
│  │  │ Target: spoke1       │    │ Target: spoke2       │           │    │
│  │  │ Pattern: apps/*/     │    │ Pattern: apps/*/     │           │    │
│  │  │          envs/prod   │    │          envs/qa     │           │    │
│  │  └──────────────────────┘    └──────────────────────┘           │    │
│  │           │                              │                        │    │
│  │           │ Creates Apps                 │ Creates Apps           │    │
│  │           ▼                              ▼                        │    │
│  │  ┌─────────────────┐          ┌─────────────────┐               │    │
│  │  │ cross-asset-prod│          │ fincad-qa       │               │    │
│  │  │ fincad-prod     │          │ kynex-qa        │               │    │
│  │  │ nx-core-prod    │          │ polypath-qa     │               │    │
│  │  │ polypath-prod   │          │                 │               │    │
│  │  └─────────────────┘          └─────────────────┘               │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                    │                                  │
                    │ Deploy                           │ Deploy
                    ▼                                  ▼
┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│      Spoke1 Cluster (PROD)       │    │      Spoke2 Cluster (QA)         │
│  spoke1.us-east-1.eksctl.io      │    │  spoke2.us-east-1.eksctl.io      │
│                                  │    │                                  │
│  Namespaces:                     │    │  Namespaces:                     │
│  ├─ cross-asset-prod             │    │  ├─ fincad-qa                    │
│  ├─ fincad-prod                  │    │  ├─ kynex-qa                     │
│  ├─ nx-core-prod                 │    │  └─ polypath-qa                  │
│  └─ polypath-prod                │    │                                  │
│                                  │    │                                  │
│  Microservices Running:          │    │  Microservices Running:          │
│  • Cross-Asset (Production)      │    │  • Fincad (QA)                   │
│  • Fincad (Production)           │    │  • Kynex (QA)                    │
│  • NX-Core (Production)          │    │  • Polypath (QA)                 │
│  • Polypath (Production)         │    │                                  │
└──────────────────────────────────┘    └──────────────────────────────────┘
```

---

## Microservices Breakdown

### 1. Cross-Asset
**Environments:** Production only
- **Deployment Target:** Spoke1 (Production Cluster)
- **Namespace:** `cross-asset-prod`
- **Path:** `apps/cross-asset/envs/prod/`

### 2. Fincad
**Environments:** Production, QA
- **Production:**
  - **Target:** Spoke1
  - **Namespace:** `fincad-prod`
  - **Path:** `apps/fincad/envs/prod/`
- **QA:**
  - **Target:** Spoke2
  - **Namespace:** `fincad-non-prod`
  - **Path:** `apps/fincad/envs/non-prod/`

### 3. Kynex
**Environments:** Non-Prod only
- **Deployment Target:** Spoke2 (Non-Prod Cluster)
- **Namespace:** `kynex-non-prod`
- **Path:** `apps/kynex/envs/non-prod/`

### 4. NX-Core
**Environments:** Production only
- **Deployment Target:** Spoke1 (Production Cluster)
- **Namespace:** `nx-core-prod`
- **Path:** `apps/nx-core/envs/prod/`

### 5. Polypath
**Environments:** Production, QA
- **Production:**
  - **Target:** Spoke1
  - **Namespace:** `polypath-prod`
  - **Path:** `apps/polypath/envs/prod/`
- **QA:**
  - **Target:** Spoke2
  - **Namespace:** `polypath-non-prod`
  - **Path:** `apps/polypath/envs/non-prod/`

---

## Deployment Flow (Step-by-Step)

```
Step 1: Developer Commits Changes
   │
   ├─> Developer pushes changes to GitHub
   │   Repository: https://github.com/numerix/gitops-demo.git
   │
   ▼
Step 2: ArgoCD Detects Changes
   │
   ├─> ArgoCD polls Git repository (every 3 minutes by default)
   ├─> Detects changes in:
   │   • appsets/ directory (ApplicationSets)
   │   • apps/*/envs/* directories (Application manifests)
   │
   ▼
Step 3: Root App Syncs ApplicationSets
   │
   ├─> oneview-all-apps (Root App) syncs
   ├─> Ensures ApplicationSets are up-to-date:
   │   • oneview-prod-appset.yml
   │   • onview-qa-appset.yml
   │
   ▼
Step 4: ApplicationSets Generate Applications
   │
   ├─> Production AppSet scans: apps/*/envs/prod
   │   Creates:
   │   • cross-asset-prod
   │   • fincad-prod
   │   • nx-core-prod
   │   • polypath-prod
   │
   ├─> QA AppSet scans: apps/*/envs/non-prod
   │   Creates:
   │   • fincad-non-prod
   │   • kynex-non-prod
   │   • polypath-non-prod
   │
   ▼
Step 5: Applications Deploy to Target Clusters
   │
   ├─> Production Apps → Spoke1 Cluster
   │   • ArgoCD connects to spoke1.us-east-1.eksctl.io
   │   • Creates namespaces (if not exist)
   │   • Applies Kubernetes manifests
   │   • Monitors health and sync status
   │
   ├─> QA Apps → Spoke2 Cluster
   │   • ArgoCD connects to spoke2.us-east-1.eksctl.io
   │   • Creates namespaces (if not exist)
   │   • Applies Kubernetes manifests
   │   • Monitors health and sync status
   │
   ▼
Step 6: Continuous Monitoring
   │
   ├─> ArgoCD continuously monitors:
   │   • Git repository for changes
   │   • Cluster state vs desired state
   │   • Application health
   │
   ├─> Auto-healing enabled:
   │   • If manual changes detected in cluster
   │   • ArgoCD reverts to Git state
   │
   └─> Auto-pruning enabled:
       • Removes resources deleted from Git
```

---

## Cluster Distribution Summary

| Microservice  | Production (Spoke1) | Non-Prod (Spoke2) |
|---------------|:-------------------:|:-----------------:|
| Cross-Asset   | ✅                  | ❌                |
| Fincad        | ✅                  | ✅                |
| Kynex         | ❌                  | ✅                |
| NX-Core       | ✅                  | ❌                |
| Polypath      | ✅                  | ✅                |
| **Total**     | **4 apps**          | **3 apps**  |

---

## GitOps Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitOps Workflow Cycle                         │
└─────────────────────────────────────────────────────────────────┘

1. CODE CHANGE
   Developer modifies:
   • Application manifests (apps/*/envs/*)
   • ApplicationSet definitions (appsets/)
   • Root application (root-argocd-app.yml)
   
   ↓

2. GIT COMMIT & PUSH
   git add .
   git commit -m "Update microservice configuration"
   git push origin main
   
   ↓

3. ARGOCD DETECTION
   • ArgoCD polls repository
   • Detects drift between Git and cluster
   • Marks applications as "OutOfSync"
   
   ↓

4. AUTOMATIC SYNC (if enabled)
   • ArgoCD applies changes automatically
   • Creates/updates Kubernetes resources
   • Waits for resources to become healthy
   
   ↓

5. HEALTH CHECK
   • Monitors deployment status
   • Checks pod health
   • Validates service endpoints
   
   ↓

6. SYNC COMPLETE
   • Application marked as "Synced"
   • Health status: "Healthy"
   • Ready for traffic
   
   ↓

7. CONTINUOUS MONITORING
   • Watches for manual changes
   • Auto-heals if drift detected
   • Prunes deleted resources
   
   └──> Back to Step 1 (next change)
```

---

## ApplicationSet Pattern Matching

### Production ApplicationSet
```yaml
Pattern: apps/*/envs/prod
Matches:
  ✅ apps/cross-asset/envs/prod/  → cross-asset-prod
  ✅ apps/fincad/envs/prod/       → fincad-prod
  ✅ apps/nx-core/envs/prod/      → nx-core-prod
  ✅ apps/polypath/envs/prod/     → polypath-prod
  ❌ apps/kynex/envs/prod/        → (doesn't exist)
```

### QA ApplicationSet
```yaml
Pattern: apps/*/envs/non-prod
Matches:
  ❌ apps/cross-asset/envs/non-prod/    → (doesn't exist)
  ✅ apps/fincad/envs/non-prod/         → fincad-non-prod
  ✅ apps/kynex/envs/non-prod/          → kynex-non-prod
  ❌ apps/nx-core/envs/non-prod/        → (doesn't exist)
  ✅ apps/polypath/envs/non-prod/       → polypath-non-prod
```

---

## Naming Convention

Applications are automatically named using the pattern:
```
{microservice-name}-{environment}
```

Examples:
- `cross-asset-prod` (from `apps/cross-asset/envs/prod`)
- `fincad-non-prod` (from `apps/fincad/envs/non-prod`)
- `nx-core-prod` (from `apps/nx-core/envs/prod`)

Namespaces follow the same pattern as application names.

---

## Key Features

### 1. Automated Sync
- Changes in Git automatically deployed
- No manual kubectl commands needed
- Consistent deployment process

### 2. Self-Healing
- Manual cluster changes reverted
- Ensures Git is single source of truth
- Prevents configuration drift

### 3. Auto-Pruning
- Resources deleted from Git are removed from cluster
- Keeps clusters clean
- Prevents orphaned resources

### 4. Multi-Cluster Management
- Single ArgoCD instance manages multiple clusters
- Centralized visibility
- Consistent policies across environments

### 5. Environment Separation
- Production isolated on Spoke1
- QA isolated on Spoke2
- Clear environment boundaries

---

## How to Add a New Microservice

```
Step 1: Create directory structure
   apps/
   └── new-service/
       ├── base/
       │   ├── deployment.yaml
       │   ├── service.yaml
       │   └── kustomization.yaml
       └── envs/
           ├── prod/
           │   └── kustomization.yaml
           └── non-prod/
               └── kustomization.yaml

Step 2: Commit and push
   git add apps/new-service
   git commit -m "Add new-service microservice"
   git push

Step 3: ArgoCD auto-discovers
   • Production AppSet finds: apps/new-service/envs/prod
   • Non-Prod AppSet finds: apps/new-service/envs/non-prod
   • Creates applications automatically:
     - new-service-prod → Spoke1
     - new-service-non-prod → Spoke2

Step 4: Verify in ArgoCD UI
   • Check application list
   • Monitor sync status
   • Verify health
```

---

## Troubleshooting Flow

```
Issue: Application not syncing
   ↓
Check 1: Is Git repository accessible?
   ├─ Yes → Continue
   └─ No → Fix repository credentials
   ↓
Check 2: Does the path exist in Git?
   ├─ Yes → Continue
   └─ No → Create missing directory/files
   ↓
Check 3: Is ApplicationSet pattern correct?
   ├─ Yes → Continue
   └─ No → Update ApplicationSet pattern
   ↓
Check 4: Is target cluster registered?
   ├─ Yes → Continue
   └─ No → Run: argocd cluster add <context>
   ↓
Check 5: Are manifests valid?
   ├─ Yes → Continue
   └─ No → Fix YAML syntax errors
   ↓
Check 6: Check ArgoCD logs
   kubectl logs -n argocd deployment/argocd-application-controller
```

---

## Monitoring Commands

```bash
# List all applications
argocd app list

# Get specific app details
argocd app get cross-asset-prod

# Watch sync status
watch argocd app list

# Check application logs
argocd app logs fincad-prod

# Force sync
argocd app sync polypath-non-prod

# View application in UI
https://localhost:8080
```

---

## Summary

**OneView** is a microservices platform with 5 core services deployed across 2 environments:
- **Production (Spoke1):** 4 services (cross-asset, fincad, nx-core, polypath)
- **Non-Prod (Spoke2):** 3 services (fincad, kynex, polypath)

All managed through **GitOps** using **ArgoCD** from a central hub cluster, ensuring:
- ✅ Automated deployments
- ✅ Self-healing capabilities
- ✅ Multi-cluster orchestration
- ✅ Git as single source of truth
- ✅ Environment isolation
