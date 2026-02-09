# Design: Scalable GitOps Platform Architecture

## 1. Overview

This design document describes the implementation of a production-grade, scalable GitOps platform using Argo CD ApplicationSets and Kustomize. The platform supports two deployment models (Kynex pooled multi-tenant and OneView siloed per-tenant) with proper governance, blast-radius control, and centralized change propagation.

### 1.1 Design Principles

1. **DRY (Don't Repeat Yourself)**: Use Kustomize bases and overlays to minimize duplication
2. **Separation of Concerns**: Clear boundaries between Kynex/OneView, prod/nonprod, platform/tenant
3. **GitOps Native**: All changes via Git commits, no manual kubectl apply
4. **Automatic Discovery**: ApplicationSets discover services without manual updates
5. **Blast Radius Control**: Changes isolated by realm, tenant, and environment
6. **Scalability**: Adding tenants/environments follows repeatable patterns

### 1.2 Architecture Layers

```
Layer 1: Bootstrap ApplicationSets (4 total)
  ├── Kynex Nonprod Bootstrap
  ├── Kynex Prod Bootstrap
  ├── OneView Nonprod Bootstrap
  └── OneView Prod Bootstrap

Layer 2: Environment ApplicationSets & AppProjects (discovered by Layer 1)
  ├── kynex-dev (ApplicationSet + AppProject)
  ├── kynex-sit (ApplicationSet + AppProject)
  ├── jefferies-dev (ApplicationSet + AppProject)
  └── ... (one per environment)

Layer 3: Service Applications (discovered by Layer 2)
  ├── kynex-marketrisk-dev
  ├── kynex-trade-dev
  ├── jefferies-marketrisk-dev
  └── ... (one per service per environment)
```

### 1.3 Repository Structure

**gitops-demo (Platform Repository)**:
- Bootstrap ApplicationSets at root
- Kustomize bases at realm level
- Kustomize overlays at environment level
- Platform service manifests (nginx-ingress)

**CDUsingArgoCD (Application Repository)**:
- Service Kustomize bases in `argocd/apps/{service}/base/`
- Service overlays in `argocd/apps/{service}/envs/{environment}/`
- Helm chart references for Helm-based services

## 2. Detailed Design

### 2.1 Bootstrap ApplicationSets

Four bootstrap ApplicationSets provide cluster initialization:


#### 2.1.1 Bootstrap File Structure

```
bootstrap/
├── kynex-nonprod-bootstrap.yaml
├── kynex-prod-bootstrap.yaml
├── oneview-nonprod-bootstrap.yaml
└── oneview-prod-bootstrap.yaml
```

#### 2.1.2 Bootstrap ApplicationSet Pattern

Each bootstrap ApplicationSet:
- Uses Git Directory Generator to discover `*/argocd/` folders
- Filters by deployment model and realm using path patterns
- Generates Applications that deploy ApplicationSets and AppProjects
- Deploys to the Argo CD namespace (`argocd`)

**Example: Kynex Nonprod Bootstrap**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kynex-nonprod-bootstrap
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - git:
      repoURL: https://github.com/CodeByMurali/gitops-demo.git
      revision: scalable
      directories:
      - path: kynex/nonprod/*/argocd
      - path: kynex/nonprod/platform/*/argocd
  template:
    metadata:
      name: 'bootstrap-{{index .path.segments 0}}-{{index .path.segments 1}}-{{index .path.segments 2}}'
      labels:
        deployment-model: kynex
        realm: nonprod
        bootstrap: "true"
    spec:
      project: default
      source:
        repoURL: https://github.com/CodeByMurali/gitops-demo.git
        targetRevision: scalable
        path: '{{.path.path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

**Key Design Decisions**:
- Path pattern `kynex/nonprod/*/argocd` discovers both environment and platform folders
- Application name includes deployment model, realm, and folder name for uniqueness
- Deploys to `argocd` namespace where Argo CD is installed
- Uses `default` AppProject (bootstrap has elevated permissions)



### 2.2 Kustomize Structure for ApplicationSets and AppProjects

#### 2.2.1 Kynex Folder Structure

```
kynex/
├── nonprod/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── applicationset.yaml
│   │   └── appproject.yaml
│   ├── dev/
│   │   └── argocd/
│   │       └── kustomization.yaml (overlay)
│   ├── sit/
│   │   └── argocd/
│   │       └── kustomization.yaml (overlay)
│   └── platform/
│       └── nginx-ingress/
│           └── argocd/
│               ├── kustomization.yaml
│               └── nginx-ingress-app.yaml
├── prod/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── applicationset.yaml
│   │   └── appproject.yaml
│   ├── preprod/
│   │   └── argocd/
│   │       └── kustomization.yaml (overlay)
│   ├── prod/
│   │   └── argocd/
│   │       └── kustomization.yaml (overlay)
│   └── platform/
│       └── nginx-ingress/
│           └── argocd/
│               ├── kustomization.yaml
│               └── nginx-ingress-app.yaml
```

#### 2.2.2 OneView Folder Structure

```
oneview/
├── nonprod/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── applicationset.yaml
│   │   └── appproject.yaml
│   ├── jefferies/
│   │   ├── poc/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml (overlay)
│   │   ├── dev/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml (overlay)
│   │   └── sit/
│   │       └── argocd/
│   │           └── kustomization.yaml (overlay)
│   ├── ocbc/
│   │   ├── dev/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml (overlay)
│   │   └── sit/
│   │       └── argocd/
│   │           └── kustomization.yaml (overlay)
│   └── platform/
│       └── nginx-ingress/
│           └── argocd/
│               ├── kustomization.yaml
│               └── nginx-ingress-app.yaml
├── prod/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── applicationset.yaml
│   │   └── appproject.yaml
│   ├── jefferies/
│   │   ├── preprod/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml (overlay)
│   │   └── prod/
│   │       └── argocd/
│   │           └── kustomization.yaml (overlay)
│   ├── ocbc/
│   │   ├── preprod/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml (overlay)
│   │   └── prod/
│   │       └── argocd/
│   │           └── kustomization.yaml (overlay)
│   └── platform/
│       └── nginx-ingress/
│           └── argocd/
│               ├── kustomization.yaml
│               └── nginx-ingress-app.yaml
```



### 2.3 Kustomize Base Templates

#### 2.3.1 Kynex Nonprod Base - ApplicationSet

**File**: `kynex/nonprod/base/applicationset.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: PLACEHOLDER_NAME
  namespace: argocd
  labels:
    deployment-model: kynex
    realm: nonprod
    environment: PLACEHOLDER_ENVIRONMENT
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - git:
      repoURL: https://github.com/CodeByMurali/CDUsingArgoCD.git
      revision: scalable
      directories:
      - path: argocd/apps/*/envs/PLACEHOLDER_ENVIRONMENT
  template:
    metadata:
      name: 'kynex-{{index .path.segments 2}}-PLACEHOLDER_ENVIRONMENT'
      labels:
        deployment-model: kynex
        realm: nonprod
        environment: PLACEHOLDER_ENVIRONMENT
        service: '{{index .path.segments 2}}'
    spec:
      project: PLACEHOLDER_PROJECT
      source:
        repoURL: https://github.com/CodeByMurali/CDUsingArgoCD.git
        targetRevision: scalable
        path: '{{.path.path}}'
        kustomize:
          enableHelm: true
      destination:
        name: PLACEHOLDER_CLUSTER
        namespace: PLACEHOLDER_NAMESPACE
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - PrunePropagationPolicy=foreground
        retry:
          limit: 3
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
```

**Placeholders to be replaced by Kustomize**:
- `PLACEHOLDER_NAME`: ApplicationSet name (e.g., `kynex-dev`)
- `PLACEHOLDER_ENVIRONMENT`: Environment name (e.g., `dev`, `sit`)
- `PLACEHOLDER_PROJECT`: AppProject name (e.g., `kynex-dev`)
- `PLACEHOLDER_CLUSTER`: Target cluster name (e.g., `kynex-nonprod-cluster`)
- `PLACEHOLDER_NAMESPACE`: Target namespace (e.g., `dev`)



#### 2.3.2 Kynex Nonprod Base - AppProject

**File**: `kynex/nonprod/base/appproject.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: PLACEHOLDER_PROJECT
  namespace: argocd
  labels:
    deployment-model: kynex
    realm: nonprod
    environment: PLACEHOLDER_ENVIRONMENT
spec:
  description: "Kynex PLACEHOLDER_ENVIRONMENT environment"
  
  sourceRepos:
  - https://github.com/CodeByMurali/CDUsingArgoCD.git
  - https://github.com/CodeByMurali/gitops-demo.git
  
  destinations:
  - namespace: 'PLACEHOLDER_NAMESPACE'
    name: PLACEHOLDER_CLUSTER
  
  clusterResourceWhitelist: []
  
  namespaceResourceWhitelist:
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  - group: ''
    kind: Service
  - group: 'apps'
    kind: Deployment
  - group: 'apps'
    kind: StatefulSet
  - group: 'apps'
    kind: DaemonSet
  - group: 'batch'
    kind: Job
  - group: 'batch'
    kind: CronJob
  - group: 'networking.k8s.io'
    kind: Ingress
  - group: 'autoscaling'
    kind: HorizontalPodAutoscaler
```

**Key Design Decisions**:
- Restricted to namespace-scoped resources only
- No cluster-wide resources (ClusterRole, ClusterRoleBinding, etc.)
- Allows both CDUsingArgoCD and gitops-demo repositories
- Destination restricted to specific cluster and namespace



#### 2.3.3 Kynex Nonprod Base - Kustomization

**File**: `kynex/nonprod/base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- applicationset.yaml
- appproject.yaml

# Common labels applied to all resources
commonLabels:
  deployment-model: kynex
  realm: nonprod
  managed-by: gitops-platform
```



### 2.4 Kustomize Environment Overlays

#### 2.4.1 Kynex Dev Overlay

**File**: `kynex/nonprod/dev/argocd/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

# Add environment-specific label
commonLabels:
  environment: dev

# Replace placeholders with environment-specific values
replacements:
- source:
    kind: ApplicationSet
    fieldPath: metadata.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - metadata.name
    options:
      delimiter: '_'
      index: 0
  value: kynex-dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.project
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.project
    - spec.generators.0.git.directories.0.path
  value: kynex-dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.name
  value: spoke2.us-east-1.eksctl.io

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.namespace
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.namespace
  value: dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.metadata.labels.environment
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.metadata.labels.environment
    - spec.generators.0.git.directories.0.path
  value: dev

- source:
    kind: AppProject
    fieldPath: metadata.name
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - metadata.name
  value: kynex-dev

- source:
    kind: AppProject
    fieldPath: spec.destinations.0.name
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - spec.destinations.0.name
  value: spoke2.us-east-1.eksctl.io

- source:
    kind: AppProject
    fieldPath: spec.destinations.0.namespace
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - spec.destinations.0.namespace
  value: dev
```

**Key Design Decisions**:
- Uses Kustomize replacements to parameterize all environment-specific values
- Cluster name, namespace, environment, and project name are all configurable
- Replacements target specific field paths for precision
- Easy to copy and customize for new environments



#### 2.4.2 OneView Tenant Overlay

**File**: `oneview/nonprod/jefferies/dev/argocd/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../base

# Add tenant and environment-specific labels
commonLabels:
  tenant: jefferies
  environment: dev

# Replace placeholders with tenant/environment-specific values
replacements:
- source:
    kind: ApplicationSet
    fieldPath: metadata.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - metadata.name
  value: jefferies-dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.project
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.project
  value: jefferies-dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.name
  value: jefferies-nonprod-cluster.us-east-1.eksctl.io

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.namespace
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.namespace
  value: dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.metadata.labels.environment
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.metadata.labels.environment
    - spec.generators.0.git.directories.0.path
  value: dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.metadata.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.metadata.name
  value: 'jefferies-{{index .path.segments 2}}-dev'

- source:
    kind: AppProject
    fieldPath: metadata.name
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - metadata.name
  value: jefferies-dev

- source:
    kind: AppProject
    fieldPath: spec.destinations.0.name
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - spec.destinations.0.name
  value: jefferies-nonprod-cluster.us-east-1.eksctl.io

- source:
    kind: AppProject
    fieldPath: spec.destinations.0.namespace
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - spec.destinations.0.namespace
  value: dev

# Add AWS account ID annotation for OneView tenants
patches:
- patch: |-
    - op: add
      path: /metadata/annotations
      value:
        aws-account-id: "123456789012"
  target:
    kind: AppProject
```

**Key Design Decisions**:
- Tenant name (jefferies) is part of ApplicationSet and AppProject names
- Cluster name includes tenant identifier
- Namespace is simple environment name (dev) since cluster is dedicated
- AWS account ID added as annotation for future cross-account access
- Application naming includes tenant: `jefferies-{service}-dev`



### 2.5 Platform Services Design

#### 2.5.1 Platform Service Structure

Platform services (like nginx-ingress) are deployed once per cluster and managed separately from tenant applications.

**File**: `kynex/nonprod/platform/nginx-ingress/argocd/nginx-ingress-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-ingress-kynex-nonprod
  namespace: argocd
  labels:
    deployment-model: kynex
    realm: nonprod
    service-type: platform
    platform-service: nginx-ingress
spec:
  project: default
  source:
    repoURL: https://kubernetes.github.io/ingress-nginx
    chart: ingress-nginx
    targetRevision: 4.8.3
    helm:
      values: |
        controller:
          replicaCount: 2
          service:
            type: LoadBalancer
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          metrics:
            enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

**File**: `kynex/nonprod/platform/nginx-ingress/argocd/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- nginx-ingress-app.yaml
```

**Key Design Decisions**:
- Platform services use Argo CD Application (not ApplicationSet)
- Deployed to `default` AppProject (platform has elevated permissions)
- Uses Helm chart directly from upstream repository
- Deployed once per cluster (not per environment)
- Separate namespace (`ingress-nginx`) for isolation
- Automated sync with retry logic



### 2.6 Complete Workflow Examples

#### 2.6.1 Workflow: Bootstrap a New Cluster

**Step 1**: Install Argo CD on the cluster
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Step 2**: Apply bootstrap ApplicationSet
```bash
# For Kynex nonprod cluster
kubectl apply -f bootstrap/kynex-nonprod-bootstrap.yaml

# For OneView Jefferies nonprod cluster
kubectl apply -f bootstrap/oneview-nonprod-bootstrap.yaml
```

**Step 3**: Bootstrap discovers and deploys
- Bootstrap scans `kynex/nonprod/*/argocd/` folders
- Finds `dev/argocd/` and `sit/argocd/`
- Creates Applications that deploy ApplicationSets and AppProjects
- ApplicationSets discover services in CDUsingArgoCD
- Services are deployed automatically

**Result**: Fully bootstrapped cluster with all services running



#### 2.6.2 Workflow: Add New Microservice

**Application Team Action**:

1. Create base manifests in CDUsingArgoCD:
```bash
cd CDUsingArgoCD
mkdir -p argocd/apps/payment/base
```

2. Create `argocd/apps/payment/base/deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment
  template:
    metadata:
      labels:
        app: payment
    spec:
      containers:
      - name: payment
        image: myregistry/payment:1.0
        ports:
        - containerPort: 8080
```

3. Create `argocd/apps/payment/base/kustomization.yml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yml
```

4. Create environment overlay `argocd/apps/payment/envs/dev/kustomization.yml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
patchesStrategicMerge:
- deployment.yml
```

5. Create `argocd/apps/payment/envs/dev/deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-deployment
spec:
  template:
    spec:
      containers:
      - name: payment
        env:
        - name: ENV
          value: "dev"
```

6. Commit to `scalable` branch:
```bash
git add argocd/apps/payment
git commit -m "Add payment service"
git push origin scalable
```

**Platform Behavior**:
- ApplicationSet `kynex-dev` syncs (within 3 minutes)
- Git Directory Generator discovers `argocd/apps/payment/envs/dev`
- Creates Application `kynex-payment-dev`
- Deploys to `dev` namespace
- Service appears in Argo CD UI

**No platform team involvement required.**



#### 2.6.3 Workflow: Add New Tenant (HSBC)

**Platform Team Action**:

1. Create folder structure:
```bash
cd gitops-demo
mkdir -p oneview/nonprod/hsbc/dev/argocd
mkdir -p oneview/nonprod/hsbc/sit/argocd
```

2. Copy overlay from existing tenant:
```bash
cp oneview/nonprod/jefferies/dev/argocd/kustomization.yaml \
   oneview/nonprod/hsbc/dev/argocd/kustomization.yaml
```

3. Customize for HSBC in `oneview/nonprod/hsbc/dev/argocd/kustomization.yaml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../base

commonLabels:
  tenant: hsbc
  environment: dev

replacements:
- source:
    kind: ApplicationSet
    fieldPath: metadata.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - metadata.name
  value: hsbc-dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.project
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.project
  value: hsbc-dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.name
  value: hsbc-nonprod-cluster.us-east-1.eksctl.io

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.namespace
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.namespace
  value: dev

- source:
    kind: ApplicationSet
    fieldPath: spec.template.metadata.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.metadata.name
  value: 'hsbc-{{index .path.segments 2}}-dev'

- source:
    kind: AppProject
    fieldPath: metadata.name
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - metadata.name
  value: hsbc-dev

- source:
    kind: AppProject
    fieldPath: spec.destinations.0.name
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - spec.destinations.0.name
  value: hsbc-nonprod-cluster.us-east-1.eksctl.io

- source:
    kind: AppProject
    fieldPath: spec.destinations.0.namespace
  targets:
  - select:
      kind: AppProject
    fieldPaths:
    - spec.destinations.0.namespace
  value: dev

patches:
- patch: |-
    - op: add
      path: /metadata/annotations
      value:
        aws-account-id: "987654321098"
  target:
    kind: AppProject
```

4. Commit to `scalable` branch:
```bash
git add oneview/nonprod/hsbc
git commit -m "Add HSBC tenant to OneView nonprod"
git push origin scalable
```

**Platform Behavior**:
- Bootstrap ApplicationSet `oneview-nonprod-bootstrap` syncs
- Discovers new `oneview/nonprod/hsbc/dev/argocd/` folder
- Creates Application `bootstrap-oneview-nonprod-hsbc`
- Deploys ApplicationSet `hsbc-dev` and AppProject `hsbc-dev`
- ApplicationSet discovers services in CDUsingArgoCD
- Services deployed to HSBC cluster

**Time: < 1 hour**



#### 2.6.4 Workflow: Change Platform-Wide Sync Policy

**Platform Team Action**:

1. Edit Kustomize base:
```bash
cd gitops-demo
vi kynex/nonprod/base/applicationset.yaml
```

2. Change sync policy:
```yaml
# Before
syncPolicy:
  automated:
    prune: true
    selfHeal: true

# After
syncPolicy:
  automated:
    prune: false  # Changed
    selfHeal: true
```

3. Commit to `scalable` branch:
```bash
git add kynex/nonprod/base/applicationset.yaml
git commit -m "Disable auto-prune for Kynex nonprod environments"
git push origin scalable
```

**Platform Behavior**:
- Bootstrap ApplicationSet syncs
- Regenerates ApplicationSets for `dev` and `sit`
- All ApplicationSets inherit the new sync policy
- All generated Applications get updated sync policy

**Result**: Changed one file, affected all Kynex nonprod environments (dev, sit)



### 2.7 Kustomize Replacements Explained

#### 2.7.1 How Kustomize Replacements Work

Kustomize replacements allow you to parameterize YAML files by replacing placeholder values with environment-specific values.

**Pattern**:
```yaml
replacements:
- source:
    kind: <ResourceKind>
    fieldPath: <path.to.field>
  targets:
  - select:
      kind: <ResourceKind>
    fieldPaths:
    - <path.to.target.field>
  value: <replacement-value>
```

**Example**: Replace cluster name
```yaml
replacements:
- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.name
  value: my-cluster.us-east-1.eksctl.io
```

This replaces `PLACEHOLDER_CLUSTER` with `my-cluster.us-east-1.eksctl.io` in the ApplicationSet.

#### 2.7.2 Providing Values During Execution

Values are provided in the environment overlay's `kustomization.yaml` file:

**Step 1**: Define base with placeholders
```yaml
# kynex/nonprod/base/applicationset.yaml
destination:
  name: PLACEHOLDER_CLUSTER
  namespace: PLACEHOLDER_NAMESPACE
```

**Step 2**: Create overlay with replacements
```yaml
# kynex/nonprod/dev/argocd/kustomization.yaml
replacements:
- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.name
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.name
  value: spoke2.us-east-1.eksctl.io  # Actual cluster name

- source:
    kind: ApplicationSet
    fieldPath: spec.template.spec.destination.namespace
  targets:
  - select:
      kind: ApplicationSet
    fieldPaths:
    - spec.template.spec.destination.namespace
  value: dev  # Actual namespace
```

**Step 3**: Build with Kustomize
```bash
kubectl kustomize kynex/nonprod/dev/argocd/
```

Output will have placeholders replaced with actual values.

#### 2.7.3 Supported Replacement Fields

The design supports replacing:
- **Cluster Name**: `spec.template.spec.destination.name`
- **Namespace**: `spec.template.spec.destination.namespace`
- **Environment**: `spec.template.metadata.labels.environment`
- **ApplicationSet Name**: `metadata.name`
- **AppProject Name**: `spec.project`
- **AWS Account ID**: `metadata.annotations.aws-account-id` (via patches)



## 3. Implementation Phases

### Phase 1: Foundation (Bootstrap & Kynex Nonprod)
1. Create bootstrap ApplicationSets (4 files)
2. Create Kynex nonprod base (applicationset.yaml, appproject.yaml, kustomization.yaml)
3. Create Kynex nonprod dev overlay
4. Create Kynex nonprod sit overlay
5. Test bootstrap and service discovery

**Deliverables**:
- `bootstrap/kynex-nonprod-bootstrap.yaml`
- `kynex/nonprod/base/*`
- `kynex/nonprod/dev/argocd/kustomization.yaml`
- `kynex/nonprod/sit/argocd/kustomization.yaml`

### Phase 2: Kynex Prod
1. Create Kynex prod base (copy and customize from nonprod)
2. Create Kynex prod preprod overlay
3. Create Kynex prod prod overlay
4. Test prod bootstrap

**Deliverables**:
- `bootstrap/kynex-prod-bootstrap.yaml`
- `kynex/prod/base/*`
- `kynex/prod/preprod/argocd/kustomization.yaml`
- `kynex/prod/prod/argocd/kustomization.yaml`

### Phase 3: OneView Nonprod
1. Create OneView nonprod base (separate from Kynex)
2. Create Jefferies nonprod overlays (poc, dev, sit)
3. Create OCBC nonprod overlays (dev, sit)
4. Fix typo: rename `jeffries` to `jefferies` in prod
5. Test OneView bootstrap

**Deliverables**:
- `bootstrap/oneview-nonprod-bootstrap.yaml`
- `oneview/nonprod/base/*`
- `oneview/nonprod/jefferies/*/argocd/kustomization.yaml`
- `oneview/nonprod/ocbc/*/argocd/kustomization.yaml`

### Phase 4: OneView Prod
1. Create OneView prod base
2. Create Jefferies prod overlays (preprod, prod)
3. Create OCBC prod overlays (preprod, prod)
4. Test OneView prod bootstrap

**Deliverables**:
- `bootstrap/oneview-prod-bootstrap.yaml`
- `oneview/prod/base/*`
- `oneview/prod/jefferies/*/argocd/kustomization.yaml`
- `oneview/prod/ocbc/*/argocd/kustomization.yaml`

### Phase 5: Platform Services
1. Create nginx-ingress Application for Kynex nonprod
2. Create nginx-ingress Application for Kynex prod
3. Create nginx-ingress Application for OneView nonprod
4. Create nginx-ingress Application for OneView prod
5. Test platform service deployment

**Deliverables**:
- `kynex/nonprod/platform/nginx-ingress/argocd/*`
- `kynex/prod/platform/nginx-ingress/argocd/*`
- `oneview/nonprod/platform/nginx-ingress/argocd/*`
- `oneview/prod/platform/nginx-ingress/argocd/*`

### Phase 6: Documentation & Testing
1. Create README with folder structure explanation
2. Document Kustomize replacements usage
3. Create onboarding guide for new tenants
4. Create onboarding guide for new services
5. Test all workflows end-to-end

**Deliverables**:
- `README.md`
- `docs/kustomize-replacements.md`
- `docs/onboarding-tenant.md`
- `docs/onboarding-service.md`



## 4. Design Validation

### 4.1 Validation Against Requirements

| Requirement | Design Solution | Status |
|-------------|----------------|--------|
| US-2.1.1: Bootstrap cluster | Four bootstrap ApplicationSets | ✅ |
| US-2.1.2: Centralized changes | Kustomize bases with overlays | ✅ |
| US-2.1.3: Kynex/OneView separation | Separate folder hierarchies | ✅ |
| US-2.1.4: Onboard new tenant | Copy overlay, customize values | ✅ |
| US-2.2.1: Auto-discover services | Git Directory Generator | ✅ |
| US-2.2.2: Environment-specific config | Kustomize overlays in CDUsingArgoCD | ✅ |
| US-2.3.1: Prod/nonprod isolation | Separate AppProjects and clusters | ✅ |
| US-2.3.2: Mandatory labels | commonLabels in Kustomize | ✅ |
| FR-3.1.1: Mandated folder structure | Preserved exactly | ✅ |
| FR-3.2.1: Kustomize bases | Bases at realm level | ✅ |
| FR-3.3.1: Git Directory Generator | Pattern: `argocd/apps/*/envs/{env}` | ✅ |
| FR-3.4.1: Restricted AppProject | Namespace-scoped resources only | ✅ |
| FR-3.5.1: Bootstrap ApplicationSets | Four separate bootstraps | ✅ |
| NFR-4.1.2: Add tenant without changes | Copy overlay, no base changes | ✅ |
| NFR-4.2.1: < 10% duplication | Bases shared, overlays minimal | ✅ |

### 4.2 Scalability Analysis

**Adding 10th Tenant**:
- Copy overlay from existing tenant: 5 minutes
- Customize 10 values (names, cluster, account): 10 minutes
- Commit and push: 2 minutes
- Bootstrap discovers and deploys: 3 minutes
- **Total: 20 minutes** ✅ (Target: < 1 hour)

**Adding 50th Microservice**:
- Create base manifests in CDUsingArgoCD: 10 minutes
- Create environment overlays: 5 minutes per environment
- Commit and push: 2 minutes
- ApplicationSets discover automatically: 3 minutes
- **Total: 20 minutes** ✅ (No platform team involvement)

**Platform-Wide Change**:
- Edit one base file: 2 minutes
- Commit and push: 2 minutes
- Bootstrap syncs and propagates: 5 minutes
- **Total: 9 minutes** ✅ (Target: < 15 minutes)

### 4.3 Duplication Analysis

**Before (Current State)**:
- 20+ ApplicationSet files with 95% identical content
- 20+ AppProject files with 90% identical content
- **Duplication: ~90%**

**After (Proposed Design)**:
- 2 ApplicationSet bases (Kynex, OneView)
- 2 AppProject bases (Kynex, OneView)
- 20+ overlays with only environment-specific values (5-10 lines each)
- **Duplication: ~5%** ✅ (Target: < 10%)



## 5. Security Considerations

### 5.1 AppProject RBAC

**Principle of Least Privilege**:
- Each environment has dedicated AppProject
- AppProjects restrict source repositories (CDUsingArgoCD, gitops-demo only)
- AppProjects restrict destination clusters (one cluster per AppProject)
- AppProjects restrict destination namespaces (one namespace per AppProject)
- AppProjects allow only namespace-scoped resources (no ClusterRole, etc.)

**Example Restrictions**:
```yaml
# Kynex Dev AppProject
destinations:
- namespace: 'dev'  # Only dev namespace
  name: spoke2.us-east-1.eksctl.io  # Only this cluster

namespaceResourceWhitelist:
- group: 'apps'
  kind: Deployment  # Only specific resource types
```

### 5.2 Secrets Management

**Current State**: No secrets in Git (placeholder only)

**Future State**:
- Use AWS Secrets Manager or External Secrets Operator
- Reference secrets by name/ARN in manifests
- Secrets injected at runtime by External Secrets Operator
- No plaintext secrets in any repository

**Example**:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: db-credentials
  data:
  - secretKey: password
    remoteRef:
      key: prod/db/password
```

### 5.3 Prod/Nonprod Isolation

**Network Isolation**:
- Separate AWS accounts (assumed)
- Separate VPCs
- Separate EKS clusters
- No network connectivity between prod and nonprod

**GitOps Isolation**:
- Separate AppProjects (kynex-dev vs kynex-prod)
- Separate bootstrap ApplicationSets
- Separate Git branches (future: nonprod branch, prod branch)

**Audit Trail**:
- All changes via Git commits
- Git history shows who changed what and when
- Argo CD UI shows sync status and drift
- Argo CD notifications for sync failures



## 6. Operational Considerations

### 6.1 Monitoring & Observability

**Argo CD UI**:
- View all Applications grouped by labels
- Filter by deployment-model, realm, tenant, environment
- See sync status, health status, and drift
- View sync history and errors

**Recommended Labels for Filtering**:
```yaml
labels:
  deployment-model: kynex | oneview
  realm: nonprod | prod
  tenant: jefferies | ocbc | hsbc  # OneView only
  environment: dev | sit | preprod | prod
  service: marketrisk | trade | ref | ...
  service-type: application | platform
```

**Metrics to Monitor**:
- Number of Applications per environment
- Sync success rate
- Sync duration
- Number of out-of-sync Applications
- Number of unhealthy Applications

### 6.2 Troubleshooting Guide

**Issue: ApplicationSet not discovering services**

Diagnosis:
1. Check ApplicationSet sync status in Argo CD UI
2. Verify Git Directory Generator path pattern
3. Check CDUsingArgoCD repository structure
4. Verify branch name (should be `scalable`)

Solution:
```bash
# View ApplicationSet status
kubectl get applicationset -n argocd kynex-dev -o yaml

# Check generated Applications
kubectl get applications -n argocd -l environment=dev

# Force sync
argocd appset get kynex-dev --refresh
```

**Issue: Application stuck in Progressing state**

Diagnosis:
1. Check Application health status
2. View sync operation details
3. Check resource events in target namespace

Solution:
```bash
# View Application details
argocd app get kynex-marketrisk-dev

# View sync status
argocd app sync kynex-marketrisk-dev --dry-run

# Check pod status
kubectl get pods -n dev -l app=marketrisk
kubectl describe pod -n dev <pod-name>
```

**Issue: Kustomize build fails**

Diagnosis:
1. Test Kustomize build locally
2. Check for syntax errors in kustomization.yaml
3. Verify base path is correct

Solution:
```bash
# Test Kustomize build locally
kubectl kustomize kynex/nonprod/dev/argocd/

# Check for errors
kubectl kustomize kynex/nonprod/dev/argocd/ --enable-alpha-plugins
```

### 6.3 Disaster Recovery

**Backup Strategy**:
- Git is the source of truth (already backed up)
- Argo CD state can be recreated from Git
- No need to backup Argo CD database

**Recovery Procedure**:
1. Provision new EKS cluster
2. Install Argo CD
3. Apply bootstrap ApplicationSet
4. Wait for automatic sync
5. Verify all Applications are healthy

**Recovery Time Objective (RTO)**: < 30 minutes



## 7. Future Enhancements

### 7.1 Progressive Delivery

**Argo Rollouts Integration**:
- Use Argo Rollouts for canary and blue-green deployments
- Define rollout strategies in application repository
- Monitor rollout progress in Argo CD UI

**Example**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: marketrisk-rollout
spec:
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 100
```

### 7.2 Multi-Cluster Management

**Argo CD Cluster Registration**:
- Register all clusters with Argo CD
- Use cluster labels for targeting
- Deploy to multiple clusters from single ApplicationSet

**Example**:
```yaml
generators:
- clusters:
    selector:
      matchLabels:
        environment: prod
        region: us-east-1
```

### 7.3 Policy Enforcement

**OPA Gatekeeper Integration**:
- Define policies as code
- Enforce policies at admission time
- Prevent non-compliant resources from being deployed

**Example Policies**:
- All Deployments must have resource limits
- All Services must have specific labels
- All Ingresses must use HTTPS

### 7.4 Notification & Alerting

**Argo CD Notifications**:
- Send notifications to Slack/Teams on sync failures
- Alert on out-of-sync Applications
- Notify on health status changes

**Example**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]
```

### 7.5 GitOps Promotion Workflow

**Branch-Based Promotion**:
- Nonprod branch for nonprod environments
- Prod branch for prod environments
- Merge nonprod → prod after validation

**Tag-Based Promotion**:
- Tag releases in CDUsingArgoCD
- ApplicationSets target specific tags
- Promote by updating tag in gitops-demo

**Example**:
```yaml
# Nonprod targets HEAD
targetRevision: scalable

# Prod targets specific tag
targetRevision: v1.2.3
```



## 8. Design Decisions Summary

### 8.1 Confirmed Decisions

| Decision | Rationale |
|----------|-----------|
| Four bootstrap ApplicationSets | Clear separation between deployment models and realms |
| Kustomize bases at realm level | Minimize duplication while maintaining clarity |
| Kustomize overlays at environment level | Environment-specific values without base changes |
| Kustomize replacements for parameterization | Native Kustomize feature, no external tools |
| Separate ApplicationSets per environment | Reduces blast radius, simplifies troubleshooting |
| Restricted AppProject permissions | Principle of least privilege |
| Git Directory Generator | Automatic service discovery |
| Automated sync with prune and selfHeal | True GitOps, no manual intervention |
| Simple namespace names for OneView | Cluster-level isolation already achieved |
| Platform services in separate folders | Clear separation from tenant applications |
| nginx-ingress as platform service PoC | Validates pattern for platform-owned services |

### 8.2 Trade-offs

| Trade-off | Decision | Rationale |
|-----------|----------|-----------|
| Kustomize components vs separate bases | Separate bases | Clarity over DRY, acceptable duplication |
| One vs four bootstrap ApplicationSets | Four | Better isolation and control |
| Inline vs external platform services | Inline | Simplicity for PoC |
| Tenant-prefixed vs simple namespaces | Simple | Cluster isolation sufficient |
| Wildcard vs restricted AppProject | Restricted | Security over convenience |

### 8.3 Open for Future Discussion

- Branch-based vs tag-based promotion workflow
- Argo Rollouts integration for progressive delivery
- OPA Gatekeeper for policy enforcement
- Multi-cluster deployment strategies
- Secrets management solution (AWS Secrets Manager vs External Secrets Operator)



## 9. Appendix

### 9.1 Complete File Tree

```
gitops-demo/
├── bootstrap/
│   ├── kynex-nonprod-bootstrap.yaml
│   ├── kynex-prod-bootstrap.yaml
│   ├── oneview-nonprod-bootstrap.yaml
│   └── oneview-prod-bootstrap.yaml
├── kynex/
│   ├── nonprod/
│   │   ├── base/
│   │   │   ├── kustomization.yaml
│   │   │   ├── applicationset.yaml
│   │   │   └── appproject.yaml
│   │   ├── dev/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml
│   │   ├── sit/
│   │   │   └── argocd/
│   │   │       └── kustomization.yaml
│   │   └── platform/
│   │       └── nginx-ingress/
│   │           └── argocd/
│   │               ├── kustomization.yaml
│   │               └── nginx-ingress-app.yaml
│   └── prod/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── applicationset.yaml
│       │   └── appproject.yaml
│       ├── preprod/
│       │   └── argocd/
│       │       └── kustomization.yaml
│       ├── prod/
│       │   └── argocd/
│       │       └── kustomization.yaml
│       └── platform/
│           └── nginx-ingress/
│               └── argocd/
│                   ├── kustomization.yaml
│                   └── nginx-ingress-app.yaml
├── oneview/
│   ├── nonprod/
│   │   ├── base/
│   │   │   ├── kustomization.yaml
│   │   │   ├── applicationset.yaml
│   │   │   └── appproject.yaml
│   │   ├── jefferies/
│   │   │   ├── poc/
│   │   │   │   └── argocd/
│   │   │   │       └── kustomization.yaml
│   │   │   ├── dev/
│   │   │   │   └── argocd/
│   │   │   │       └── kustomization.yaml
│   │   │   └── sit/
│   │   │       └── argocd/
│   │   │           └── kustomization.yaml
│   │   ├── ocbc/
│   │   │   ├── dev/
│   │   │   │   └── argocd/
│   │   │   │       └── kustomization.yaml
│   │   │   └── sit/
│   │   │       └── argocd/
│   │   │           └── kustomization.yaml
│   │   └── platform/
│   │       └── nginx-ingress/
│   │           └── argocd/
│   │               ├── kustomization.yaml
│   │               └── nginx-ingress-app.yaml
│   └── prod/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── applicationset.yaml
│       │   └── appproject.yaml
│       ├── jefferies/
│       │   ├── preprod/
│       │   │   └── argocd/
│       │   │       └── kustomization.yaml
│       │   └── prod/
│       │       └── argocd/
│       │           └── kustomization.yaml
│       ├── ocbc/
│       │   ├── preprod/
│       │   │   └── argocd/
│       │   │       └── kustomization.yaml
│       │   └── prod/
│       │       └── argocd/
│       │           └── kustomization.yaml
│       └── platform/
│           └── nginx-ingress/
│               └── argocd/
│                   ├── kustomization.yaml
│                   └── nginx-ingress-app.yaml
├── docs/
│   ├── kustomize-replacements.md
│   ├── onboarding-tenant.md
│   └── onboarding-service.md
└── README.md
```

### 9.2 Glossary

- **ApplicationSet**: Argo CD resource that generates multiple Applications from templates
- **AppProject**: Argo CD resource that defines RBAC boundaries for Applications
- **Bootstrap**: Root-level ApplicationSet that discovers and deploys other ApplicationSets
- **Kustomize Base**: Template YAML files with placeholders
- **Kustomize Overlay**: Environment-specific customizations that reference a base
- **Kustomize Replacement**: Mechanism to replace placeholder values in bases
- **Git Directory Generator**: ApplicationSet generator that discovers directories in Git
- **Deployment Model**: Kynex (pooled) or OneView (siloed)
- **Realm**: Prod or nonprod
- **Tenant**: Customer/client in OneView model (e.g., Jefferies, OCBC)
- **Environment**: dev, sit, preprod, prod
- **Platform Service**: Infrastructure service managed by platform team (e.g., nginx-ingress)

### 9.3 References

- [Argo CD ApplicationSets Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Kustomize Replacements](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/replacements/)
- [GitOps Principles](https://opengitops.dev/)
- [Argo CD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

---

**Design Document Version**: 1.0  
**Last Updated**: 2026-02-09  
**Status**: Ready for Implementation
