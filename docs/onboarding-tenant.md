# Tenant Onboarding Guide

This guide provides step-by-step instructions for adding a new tenant to the OneView deployment model.

## Overview

Adding a new tenant (e.g., HSBC) to OneView involves:
1. Creating folder structure
2. Creating Kustomize overlays for each environment
3. Committing changes to Git
4. Verifying automatic deployment

**Time Required**: < 1 hour

## Prerequisites

- Git access to gitops-demo repository
- Understanding of Kustomize overlays (see [kustomize-replacements.md](kustomize-replacements.md))
- Tenant-specific information:
  - Tenant name (e.g., `hsbc`)
  - AWS account ID
  - Target cluster names
  - Required environments (poc, dev, sit, preprod, prod)

## Step-by-Step Instructions

### Step 1: Create Folder Structure

Create the folder structure for the new tenant in both nonprod and prod realms:

```bash
cd gitops-demo

# Nonprod environments
mkdir -p oneview/nonprod/hsbc/poc/argocd
mkdir -p oneview/nonprod/hsbc/dev/argocd
mkdir -p oneview/nonprod/hsbc/sit/argocd

# Prod environments
mkdir -p oneview/prod/hsbc/preprod/argocd
mkdir -p oneview/prod/hsbc/prod/argocd
```

### Step 2: Create Nonprod Overlays

#### 2.1 Create POC Environment

Create `oneview/nonprod/hsbc/poc/argocd/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../argocd/base

commonLabels:
  tenant: hsbc
  environment: poc

patches:
- target:
    kind: ApplicationSet
  patch: |-
    - op: replace
      path: /metadata/name
      value: hsbc-poc
    - op: replace
      path: /metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /metadata/labels/environment
      value: poc
    - op: replace
      path: /spec/template/metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /spec/template/metadata/labels/environment
      value: poc
    - op: replace
      path: /spec/template/metadata/name
      value: hsbc-{{index .path.segments 2}}-poc
    - op: replace
      path: /spec/template/spec/project
      value: hsbc-poc
    - op: replace
      path: /spec/template/spec/destination/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/template/spec/destination/namespace
      value: hsbc-poc
    - op: replace
      path: /spec/generators/0/git/directories/0/path
      value: argocd/apps/*/envs/poc

- target:
    kind: AppProject
  patch: |-
    - op: replace
      path: /metadata/name
      value: hsbc-poc
    - op: replace
      path: /metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /metadata/labels/environment
      value: poc
    - op: replace
      path: /spec/description
      value: "OneView hsbc poc environment"
    - op: replace
      path: /spec/destinations/0/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/destinations/0/namespace
      value: hsbc-poc
    - op: add
      path: /metadata/annotations
      value:
        aws-account-id: "111222333444"
```

#### 2.2 Create Dev Environment

Create `oneview/nonprod/hsbc/dev/argocd/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../argocd/base

commonLabels:
  tenant: hsbc
  environment: dev

patches:
- target:
    kind: ApplicationSet
  patch: |-
    - op: replace
      path: /metadata/name
      value: hsbc-dev
    - op: replace
      path: /metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /metadata/labels/environment
      value: dev
    - op: replace
      path: /spec/template/metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /spec/template/metadata/labels/environment
      value: dev
    - op: replace
      path: /spec/template/metadata/name
      value: hsbc-{{index .path.segments 2}}-dev
    - op: replace
      path: /spec/template/spec/project
      value: hsbc-dev
    - op: replace
      path: /spec/template/spec/destination/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/template/spec/destination/namespace
      value: hsbc-dev
    - op: replace
      path: /spec/generators/0/git/directories/0/path
      value: argocd/apps/*/envs/dev

- target:
    kind: AppProject
  patch: |-
    - op: replace
      path: /metadata/name
      value: hsbc-dev
    - op: replace
      path: /metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /metadata/labels/environment
      value: dev
    - op: replace
      path: /spec/description
      value: "OneView hsbc dev environment"
    - op: replace
      path: /spec/destinations/0/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/destinations/0/namespace
      value: hsbc-dev
    - op: add
      path: /metadata/annotations
      value:
        aws-account-id: "111222333444"
```

#### 2.3 Create SIT Environment

Create `oneview/nonprod/hsbc/sit/argocd/kustomization.yaml` (similar to dev, change `dev` to `sit`).

### Step 3: Create Prod Overlays

#### 3.1 Create Preprod Environment

Create `oneview/prod/hsbc/preprod/argocd/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../argocd/base

commonLabels:
  tenant: hsbc
  environment: preprod

patches:
- target:
    kind: ApplicationSet
  patch: |-
    - op: replace
      path: /metadata/name
      value: hsbc-preprod
    - op: replace
      path: /metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /metadata/labels/environment
      value: preprod
    - op: replace
      path: /spec/template/metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /spec/template/metadata/labels/environment
      value: preprod
    - op: replace
      path: /spec/template/metadata/name
      value: hsbc-{{index .path.segments 2}}-preprod
    - op: replace
      path: /spec/template/spec/project
      value: hsbc-preprod
    - op: replace
      path: /spec/template/spec/destination/name
      value: spoke1.us-east-1.eksctl.io
    - op: replace
      path: /spec/template/spec/destination/namespace
      value: hsbc-preprod
    - op: replace
      path: /spec/generators/0/git/directories/0/path
      value: argocd/apps/*/envs/preprod

- target:
    kind: AppProject
  patch: |-
    - op: replace
      path: /metadata/name
      value: hsbc-preprod
    - op: replace
      path: /metadata/labels/tenant
      value: hsbc
    - op: replace
      path: /metadata/labels/environment
      value: preprod
    - op: replace
      path: /spec/description
      value: "OneView hsbc preprod environment"
    - op: replace
      path: /spec/destinations/0/name
      value: spoke1.us-east-1.eksctl.io
    - op: replace
      path: /spec/destinations/0/namespace
      value: hsbc-preprod
    - op: add
      path: /metadata/annotations
      value:
        aws-account-id: "555666777888"
```

#### 3.2 Create Prod Environment

Create `oneview/prod/hsbc/prod/argocd/kustomization.yaml` (similar to preprod, change `preprod` to `prod`).

### Step 4: Test Locally

Before committing, test the Kustomize overlays:

```bash
# Test nonprod overlays
kubectl kustomize oneview/nonprod/hsbc/poc/argocd/
kubectl kustomize oneview/nonprod/hsbc/dev/argocd/
kubectl kustomize oneview/nonprod/hsbc/sit/argocd/

# Test prod overlays
kubectl kustomize oneview/prod/hsbc/preprod/argocd/
kubectl kustomize oneview/prod/hsbc/prod/argocd/

# Verify specific values
kubectl kustomize oneview/nonprod/hsbc/dev/argocd/ | grep "name: hsbc-dev"
kubectl kustomize oneview/nonprod/hsbc/dev/argocd/ | grep "namespace: hsbc-dev"
kubectl kustomize oneview/nonprod/hsbc/dev/argocd/ | grep "aws-account-id"
```

### Step 5: Commit and Push

```bash
git add oneview/nonprod/hsbc oneview/prod/hsbc
git commit -m "Add HSBC tenant to OneView"
git push origin scalable
```

### Step 6: Verify Automatic Deployment

Wait 1-3 minutes for Argo CD to sync, then verify:

```bash
# Check ApplicationSets
kubectl get applicationsets -n argocd | grep hsbc

# Expected output:
# hsbc-poc       <age>
# hsbc-dev       <age>
# hsbc-sit       <age>
# hsbc-preprod   <age>
# hsbc-prod      <age>

# Check AppProjects
kubectl get appprojects -n argocd | grep hsbc

# Check Applications
argocd app list | grep hsbc

# Check services deployed
kubectl get pods -n hsbc-dev --context <spoke2-context>
kubectl get pods -n hsbc-prod --context <spoke1-context>
```

## Configuration Reference

### Key Values to Customize

| Field | Description | Example |
|-------|-------------|---------|
| Tenant name | Lowercase tenant identifier | `hsbc`, `citi`, `bofa` |
| AWS Account ID (nonprod) | AWS account for nonprod | `"111222333444"` |
| AWS Account ID (prod) | AWS account for prod | `"555666777888"` |
| Cluster name (nonprod) | Target cluster for nonprod | `spoke2.us-east-1.eksctl.io` |
| Cluster name (prod) | Target cluster for prod | `spoke1.us-east-1.eksctl.io` |
| Namespace pattern | Tenant-specific namespace | `{tenant}-{environment}` |

### Namespace Naming Convention

OneView uses tenant-prefixed namespaces for complete isolation:
- POC: `{tenant}-poc` (e.g., `hsbc-poc`)
- Dev: `{tenant}-dev` (e.g., `hsbc-dev`)
- SIT: `{tenant}-sit` (e.g., `hsbc-sit`)
- Preprod: `{tenant}-preprod` (e.g., `hsbc-preprod`)
- Prod: `{tenant}-prod` (e.g., `hsbc-prod`)

This naming convention:
- Prevents resource conflicts between tenants
- Eliminates SharedResourceWarnings in Argo CD
- Enables tenant-specific resource quotas and network policies
- Provides clear visibility of resource ownership

## Troubleshooting

### Issue: ApplicationSets not created

**Check**: Verify bootstrap ApplicationSet is syncing
```bash
kubectl get applicationset oneview-nonprod-bootstrap -n argocd
argocd app get bootstrap-oneview-nonprod-hsbc-dev
```

**Solution**: Manually sync the bootstrap
```bash
argocd app sync bootstrap-oneview-nonprod-hsbc-dev
```

### Issue: Services not discovered

**Check**: Verify services exist in CDUsingArgoCD repository
```bash
# Services should be in: argocd/apps/{service}/envs/{environment}/
```

**Solution**: Ensure service overlays exist for the environments you're deploying to.

### Issue: Permission denied errors

**Check**: Verify AppProject permissions
```bash
kubectl get appproject hsbc-dev -n argocd -o yaml
```

**Solution**: Ensure AppProject allows the necessary resource types and namespaces.

## Best Practices

1. **Use consistent naming**: Always use lowercase for tenant names
2. **Test locally first**: Always run `kubectl kustomize` before committing
3. **Document AWS accounts**: Keep a record of which AWS account IDs map to which tenants
4. **Follow the pattern**: Copy from existing tenants (Jefferies/OCBC) and modify
5. **Verify deployment**: Always check that services are actually running after onboarding

## Next Steps

After onboarding a tenant:
1. Add services to CDUsingArgoCD repository (see [onboarding-service.md](onboarding-service.md))
2. Configure tenant-specific settings (resource quotas, network policies, etc.)
3. Set up monitoring and alerting for the tenant
4. Document tenant-specific configurations

## Support

For issues or questions, contact the platform team or refer to:
- [Kustomize Replacements Guide](kustomize-replacements.md)
- Design document: `.kiro/specs/scalable-gitops-platform/design.md`
