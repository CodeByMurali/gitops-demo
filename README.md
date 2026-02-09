# Scalable GitOps Platform

Production-grade GitOps platform using Argo CD ApplicationSets and Kustomize for automated service deployment across multiple clusters and tenants.

## Architecture Overview

This platform implements a 3-layer architecture for scalable, automated GitOps deployments:

```
Layer 1: Bootstrap ApplicationSets (4 total)
  ├── Kynex Nonprod Bootstrap
  ├── Kynex Prod Bootstrap
  ├── OneView Nonprod Bootstrap
  └── OneView Prod Bootstrap

Layer 2: Environment ApplicationSets & AppProjects (auto-discovered)
  ├── kynex-dev, kynex-sit (nonprod)
  ├── kynex-preprod, kynex-prod (prod)
  ├── jefferies-poc, jefferies-dev, jefferies-sit (nonprod)
  ├── jefferies-preprod, jefferies-prod (prod)
  └── ocbc-dev, ocbc-sit, ocbc-preprod, ocbc-prod

Layer 3: Service Applications (auto-discovered)
  └── Automatically discovered from CDUsingArgoCD repository
```

## Repository Structure

```
gitops-demo/
├── bootstrap/                          # Layer 1: Bootstrap ApplicationSets
│   ├── kynex-nonprod-bootstrap.yaml
│   ├── kynex-prod-bootstrap.yaml
│   ├── oneview-nonprod-bootstrap.yaml
│   └── oneview-prod-bootstrap.yaml
│
├── kynex/                              # Kynex deployment model (pooled multi-tenant)
│   ├── nonprod/
│   │   ├── argocd/
│   │   │   ├── base/                   # Base templates for ApplicationSets & AppProjects
│   │   │   │   ├── applicationset.yaml
│   │   │   │   ├── appproject.yaml
│   │   │   │   └── kustomization.yaml
│   │   │   └── platform/               # Platform services (nginx-ingress)
│   │   │       └── nginx-ingress-app.yaml
│   │   ├── dev/argocd/                 # Dev environment overlay
│   │   │   └── kustomization.yaml
│   │   └── sit/argocd/                 # SIT environment overlay
│   │       └── kustomization.yaml
│   └── prod/
│       ├── argocd/base/
│       ├── argocd/platform/
│       ├── preprod/argocd/
│       └── prod/argocd/
│
└── oneview/                            # OneView deployment model (siloed per-tenant)
    ├── nonprod/
    │   ├── argocd/base/
    │   ├── argocd/platform/
    │   ├── jefferies/
    │   │   ├── poc/argocd/
    │   │   ├── dev/argocd/
    │   │   └── sit/argocd/
    │   └── ocbc/
    │       ├── dev/argocd/
    │       └── sit/argocd/
    └── prod/
        ├── argocd/base/
        ├── argocd/platform/
        ├── jefferies/
        │   ├── preprod/argocd/
        │   └── prod/argocd/
        └── ocbc/
            ├── preprod/argocd/
            └── prod/argocd/
```

## Cluster Configuration

| Cluster | Role | Deployment Models | Environments |
|---------|------|-------------------|--------------|
| **hub** | Argo CD Control Plane | N/A | Argo CD installed here |
| **spoke1** | Prod Realm | Kynex, OneView | preprod, prod |
| **spoke2** | Nonprod Realm | Kynex, OneView | poc, dev, sit |

### Namespace Strategy

**Kynex (Pooled Multi-Tenant)**:
- Simple namespace names: `dev`, `sit`, `preprod`, `prod`
- All services share the same namespace per environment
- Cost-efficient for internal services

**OneView (Siloed Per-Tenant)**:
- Tenant-specific namespaces: `{tenant}-{environment}`
- Examples: `jefferies-dev`, `jefferies-prod`, `ocbc-dev`, `ocbc-prod`
- Complete isolation between tenants
- Eliminates SharedResourceWarnings
- Enables tenant-specific resource quotas and policies

## Quick Start

### Prerequisites
- kubectl configured with access to hub, spoke1, spoke2 clusters
- Argo CD CLI installed
- Git access to gitops-demo and CDUsingArgoCD repositories

### Deploy Platform

1. **Install Argo CD on hub cluster**:
```bash
kubectl config use-context <hub-cluster-context>
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. **Register spoke clusters**:
```bash
argocd cluster add <spoke1-context> --name spoke1.us-east-1.eksctl.io
argocd cluster add <spoke2-context> --name spoke2.us-east-1.eksctl.io
```

3. **Deploy bootstrap ApplicationSets**:
```bash
kubectl apply -f bootstrap/kynex-nonprod-bootstrap.yaml
kubectl apply -f bootstrap/kynex-prod-bootstrap.yaml
kubectl apply -f bootstrap/oneview-nonprod-bootstrap.yaml
kubectl apply -f bootstrap/oneview-prod-bootstrap.yaml
```

4. **Deploy platform services**:
```bash
kubectl apply -k kynex/nonprod/argocd/platform/
kubectl apply -k kynex/prod/argocd/platform/
kubectl apply -k oneview/nonprod/argocd/platform/
kubectl apply -k oneview/prod/argocd/platform/
```

5. **Verify deployment**:
```bash
# Check ApplicationSets
kubectl get applicationsets -n argocd

# Check Applications
argocd app list

# Check services on spoke clusters
kubectl get pods -n dev --context <spoke2-context>
kubectl get pods -n prod --context <spoke1-context>
```

## Key Features

### 1. Automatic Service Discovery
Services are automatically discovered from the CDUsingArgoCD repository. No manual ApplicationSet updates required.

### 2. DRY Principle
- Base templates defined once at realm level
- Environment overlays use Kustomize patches
- Minimal duplication (<10%)

### 3. Blast Radius Control
- Changes isolated by realm (nonprod/prod)
- Changes isolated by tenant (Kynex/Jefferies/OCBC)
- Changes isolated by environment (dev/sit/preprod/prod)

### 4. Restricted Permissions
AppProjects enforce least-privilege access:
- No cluster-wide resources allowed
- Only namespace-scoped resources permitted
- Specific resource types whitelisted

### 5. Multi-Tenant Support
- **Kynex**: Pooled multi-tenant model (shared namespaces)
- **OneView**: Siloed per-tenant model with dedicated namespaces
- Tenant-specific namespaces prevent resource conflicts and SharedResourceWarnings

## Workflows

### Adding a New Service
See [docs/onboarding-service.md](docs/onboarding-service.md)

### Adding a New Tenant
See [docs/onboarding-tenant.md](docs/onboarding-tenant.md)

### Making Platform-Wide Changes
Edit the base templates in `{deployment-model}/{realm}/argocd/base/` and commit. Changes automatically propagate to all environments.

## Documentation

- [Kustomize Replacements Guide](docs/kustomize-replacements.md)
- [Tenant Onboarding Guide](docs/onboarding-tenant.md)
- [Service Onboarding Guide](docs/onboarding-service.md)

## Support

For issues or questions, refer to the design document at `.kiro/specs/scalable-gitops-platform/design.md`
