# OneView Platform Architecture - Production Guide

## 1. Microservices Deployment Topology

| Microservice | Dev (Spoke2) | QA (Spoke2) | Prod (Spoke1) | Namespace Pattern |
|--------------|:------------:|:-----------:|:-------------:|-------------------|
| cross-asset  | ❌           | ✅          | ✅            | `{svc}-{env}`     |
| fincad       | ✅           | ✅          | ✅            | `{svc}-{env}`     |
| kynex        | ✅           | ✅          | ❌            | `{svc}-{env}`     |
| nx-core      | ❌           | ✅          | ✅            | `{svc}-{env}`     |
| polypath     | ✅           | ✅          | ✅            | `{svc}-{env}`     |

**Cluster Mapping:**
- **Hub:** `hub.us-east-1.eksctl.io` → ArgoCD control plane only
- **Spoke1 (Prod):** `spoke1.us-east-1.eksctl.io` → Production workloads
- **Spoke2 (Non-Prod):** `spoke2.us-east-1.eksctl.io` → Dev + QA workloads

**Example Namespaces:**
- `fincad-prod` → Spoke1
- `fincad-dev`, `fincad-qa` → Spoke2
- `cross-asset-qa`, `cross-asset-prod` → Spoke2, Spoke1

---

## 2. GitOps Repository Structure & Flow

### Repository Layout
```
gitops-demo/
├── root-argocd-app.yml              # App-of-Apps (bootstraps everything)
├── clusters/                         # ApplicationSets per account/cluster
│   ├── prod-account.yml             # Spoke1: apps/*/envs/prod
│   └── non-prod-account.yml         # Spoke2: apps/*/envs/{dev,qa}
└── apps/                             # Microservice manifests
    └── {microservice}/
        ├── base/                     # Base Kustomize resources
        │   ├── deployment.yml
        │   ├── service.yml
        │   └── kustomization.yml
        └── envs/                     # Environment overlays
            ├── dev/
            │   ├── kustomization.yml
            │   ├── deployment.yml    # Patches
            │   ├── version.yml
            │   └── settings.yml
            ├── qa/
            └── prod/
```

### ArgoCD + ApplicationSet + Kustomize Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Root App (oneview-all-apps)                                  │
│    - Watches: clusters/                                         │
│    - Creates: ApplicationSets                                   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. ApplicationSets (Git Directory Generator)                    │
│                                                                  │
│  prod-account.yml:                                              │
│    Pattern: apps/*/envs/prod                                    │
│    Target: spoke1.us-east-1.eksctl.io                           │
│                                                                  │
│  non-prod-account.yml:                                          │
│    Pattern: apps/*/envs/{dev,qa}                                │
│    Target: spoke2.us-east-1.eksctl.io                           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. Auto-Generated Applications                                  │
│    - fincad-prod → spoke1                                       │
│    - fincad-dev, fincad-qa → spoke2                             │
│    - cross-asset-qa, cross-asset-prod → spoke2, spoke1          │
│    - etc.                                                       │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. Kustomize Build (per application)                            │
│    - Reads: apps/{svc}/envs/{env}/kustomization.yml             │
│    - Merges: base + env patches                                 │
│    - Outputs: Final K8s manifests                               │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Deploy to Target Cluster                                     │
│    - ArgoCD applies manifests to spoke1 or spoke2               │
│    - Creates namespace: {microservice}-{env}                    │
│    - Monitors health & sync status                              │
└─────────────────────────────────────────────────────────────────┘
```

---

### Kustomize Example: fincad-prod

#### Base (`apps/fincad/base/deployment.yml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fincad-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fincad
  template:
    metadata:
      labels:
        app: fincad
    spec:
      containers:
      - name: fincad
        image: docker.io/kostiscodefresh/simple-env-app:1.0
        ports:
        - containerPort: 8080
```

#### Prod Overlay (`apps/fincad/envs/prod/deployment.yml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fincad-deployment
spec:
  template:
    spec:
      containers:
      - name: fincad
        env:
        - name: ENV
          value: "prod-us"
        - name: GPU_ENABLED
          value: "1"
```

#### Kustomization (`apps/fincad/envs/prod/kustomization.yml`)
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patchesStrategicMerge:
- deployment.yml
- version.yml
- replicas.yml
- settings.yml
```

#### Final Rendered Manifest (Kustomize Output)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fincad-deployment
spec:
  replicas: 2                          # From base
  selector:
    matchLabels:
      app: fincad
  template:
    metadata:
      labels:
        app: fincad
    spec:
      containers:
      - name: fincad
        image: docker.io/kostiscodefresh/simple-env-app:1.0
        ports:
        - containerPort: 8080
        env:                            # Merged from prod overlay
        - name: ENV
          value: "prod-us"
        - name: GPU_ENABLED
          value: "1"
```

#### Deployment to Kubernetes
```bash
# ArgoCD executes internally:
kustomize build apps/fincad/envs/prod | kubectl apply -n fincad-prod -f -

# Deployed to: spoke1.us-east-1.eksctl.io
# Namespace: fincad-prod (auto-created)
```

---

## 3. Add New Microservice (4 Steps)

### Step 1: Create Directory Structure
```bash
apps/
└── new-service/
    ├── base/
    │   ├── deployment.yml
    │   ├── service.yml
    │   └── kustomization.yml
    └── envs/
        ├── dev/
        │   ├── kustomization.yml
        │   └── deployment.yml
        ├── qa/
        │   ├── kustomization.yml
        │   └── deployment.yml
        └── prod/
            ├── kustomization.yml
            └── deployment.yml
```

### Step 2: Commit & Push
```bash
git add apps/new-service
git commit -m "Add new-service microservice"
git push
```

### Step 3: ArgoCD Auto-Discovery (No Changes Required)
- **prod-account** ApplicationSet scans `apps/*/envs/prod` → finds `new-service-prod`
- **non-prod-account** ApplicationSet scans `apps/*/envs/{dev,qa}` → finds `new-service-dev`, `new-service-qa`
- Applications auto-created within 3 minutes (default poll interval)

### Step 4: Verify
```bash
argocd app list | grep new-service
# new-service-dev    Synced  Healthy  spoke2  new-service-dev
# new-service-qa     Synced  Healthy  spoke2  new-service-qa
# new-service-prod   Synced  Healthy  spoke1  new-service-prod
```

**What Does NOT Require Changes:**
- ❌ ApplicationSets (pattern `apps/*/envs/*` matches automatically)
- ❌ Root application
- ❌ Cluster configuration
- ❌ ArgoCD settings

---

## 4. Add New Environment (3 Steps)

### Scenario: Add `staging` environment to Spoke1

#### Step 1: Create Environment Overlays
```bash
# For each microservice that needs staging:
apps/fincad/envs/staging/
├── kustomization.yml
├── deployment.yml
└── settings.yml
```

#### Step 2: Update/Create ApplicationSet
**Option A:** Modify existing `prod-account.yml`
```yaml
spec:
  generators:
  - git:
      directories:
      - path: apps/*/envs/prod
      - path: apps/*/envs/staging    # Add this line
```

**Option B:** Create new `staging-account.yml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: staging-account
  namespace: argocd
spec:
  goTemplate: true
  generators:
  - git:
      repoURL: https://github.com/CodeByMurali/gitops-demo.git
      revision: HEAD
      directories:
      - path: apps/*/envs/staging
  template:
    metadata:
      name: '{{index .path.segments 1}}-{{index .path.segments 3}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/CodeByMurali/gitops-demo.git
        targetRevision: HEAD
        path: '{{.path.path}}'
      destination:
        name: spoke1.us-east-1.eksctl.io    # Target cluster
        namespace: '{{index .path.segments 1}}-{{index .path.segments 3}}'
      syncPolicy:
        syncOptions:
          - CreateNamespace=true
        automated:
          prune: true
          selfHeal: true
```

#### Step 3: Commit & Push
```bash
git add apps/*/envs/staging clusters/staging-account.yml
git commit -m "Add staging environment"
git push
```

**Cluster Selection Logic:**
- Controlled by `destination.name` in ApplicationSet
- `spoke1.us-east-1.eksctl.io` → Production cluster
- `spoke2.us-east-1.eksctl.io` → Non-production cluster
- Must match cluster name registered in ArgoCD: `argocd cluster list`

**What Requires Changes:**
- ✅ ApplicationSet (add directory pattern or create new)
- ✅ Environment overlays (per microservice)
- ❌ Base manifests (unchanged)
- ❌ Root application (if new ApplicationSet in `clusters/`)

---

## Key Design Principles

1. **Separation of Concerns:**
   - `clusters/` → Account/cluster-level ApplicationSets
   - `apps/` → Microservice manifests
   - Base → Environment-agnostic
   - Overlays → Environment-specific patches

2. **GitOps Pattern:**
   - Git = single source of truth
   - ArgoCD = reconciliation engine
   - Kustomize = manifest templating
   - No manual `kubectl apply`

3. **Auto-Discovery:**
   - ApplicationSets use Git directory generator
   - Pattern `apps/*/envs/{env}` auto-discovers new services
   - No manual application creation

4. **Cluster Targeting:**
   - Prod account → Spoke1
   - Non-prod account → Spoke2
   - Defined in ApplicationSet `destination.name`

5. **Namespace Convention:**
   - `{microservice}-{environment}`
   - Auto-created via `CreateNamespace=true`
   - Isolated per service + env

---

## Production Checklist

- [ ] All ApplicationSets use `automated: {prune: true, selfHeal: true}`
- [ ] Cluster names match `argocd cluster list` output
- [ ] Base manifests are environment-agnostic
- [ ] Overlays only contain patches (not full resources)
- [ ] Git repository is single source of truth
- [ ] No manual changes to clusters (GitOps only)
- [ ] ApplicationSet patterns cover all required environments
- [ ] Namespace naming follows `{svc}-{env}` convention
