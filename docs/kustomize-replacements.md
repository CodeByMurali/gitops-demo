# Kustomize Replacements Guide

This guide explains how Kustomize replacements work in the scalable GitOps platform and how to use them when creating new environments or tenants.

## Overview

Kustomize replacements allow us to parameterize YAML files by replacing placeholder values with environment-specific values. This enables the DRY (Don't Repeat Yourself) principle - we define base templates once and customize them per environment using overlays.

## How Replacements Work

### Base Template (with placeholders)

The base template contains placeholder values that will be replaced:

```yaml
# kynex/nonprod/argocd/base/applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: PLACEHOLDER_NAME
spec:
  template:
    spec:
      project: PLACEHOLDER_PROJECT
      destination:
        name: PLACEHOLDER_CLUSTER
        namespace: PLACEHOLDER_NAMESPACE
```

### Environment Overlay (with replacements)

The overlay specifies the actual values using JSON patches:

```yaml
# kynex/nonprod/dev/argocd/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../argocd/base

patches:
- target:
    kind: ApplicationSet
  patch: |-
    - op: replace
      path: /metadata/name
      value: kynex-dev
    - op: replace
      path: /spec/template/spec/project
      value: kynex-dev
    - op: replace
      path: /spec/template/spec/destination/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/template/spec/destination/namespace
      value: dev
```

### Result

When you run `kubectl kustomize kynex/nonprod/dev/argocd/`, Kustomize applies the patches and produces:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kynex-dev
spec:
  template:
    spec:
      project: kynex-dev
      destination:
        name: spoke2.us-east-1.eksctl.io
        namespace: dev
```

## Supported Replacement Fields

### ApplicationSet Fields

| Field Path | Description | Example Value |
|------------|-------------|---------------|
| `/metadata/name` | ApplicationSet name | `kynex-dev`, `jefferies-prod` |
| `/metadata/labels/tenant` | Tenant label (OneView only) | `jefferies`, `ocbc` |
| `/metadata/labels/environment` | Environment label | `dev`, `sit`, `prod` |
| `/spec/template/metadata/name` | Application name template | `kynex-{{index .path.segments 2}}-dev` |
| `/spec/template/spec/project` | Target AppProject | `kynex-dev`, `jefferies-prod` |
| `/spec/template/spec/destination/name` | Target cluster | `spoke1.us-east-1.eksctl.io` |
| `/spec/template/spec/destination/namespace` | Target namespace | `dev`, `jefferies-dev` |
| `/spec/generators/0/git/directories/0/path` | Service discovery path | `argocd/apps/*/envs/dev` |

### AppProject Fields

| Field Path | Description | Example Value |
|------------|-------------|---------------|
| `/metadata/name` | AppProject name | `kynex-dev`, `ocbc-prod` |
| `/metadata/labels/tenant` | Tenant label | `jefferies`, `ocbc` |
| `/metadata/labels/environment` | Environment label | `dev`, `prod` |
| `/spec/description` | Project description | `"Kynex dev environment"` |
| `/spec/destinations/0/name` | Allowed cluster | `spoke2.us-east-1.eksctl.io` |
| `/spec/destinations/0/namespace` | Allowed namespace | `dev`, `jefferies-dev` |
| `/metadata/annotations/aws-account-id` | AWS account (OneView) | `"123456789012"` |

## Complete Examples

### Example 1: Kynex Dev Environment

**Base**: `kynex/nonprod/argocd/base/`

**Overlay**: `kynex/nonprod/dev/argocd/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../argocd/base

commonLabels:
  environment: dev

patches:
- target:
    kind: ApplicationSet
  patch: |-
    - op: replace
      path: /metadata/name
      value: kynex-dev
    - op: replace
      path: /spec/template/spec/project
      value: kynex-dev
    - op: replace
      path: /spec/template/spec/destination/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/template/spec/destination/namespace
      value: dev
    - op: replace
      path: /spec/generators/0/git/directories/0/path
      value: argocd/apps/*/envs/dev

- target:
    kind: AppProject
  patch: |-
    - op: replace
      path: /metadata/name
      value: kynex-dev
    - op: replace
      path: /spec/destinations/0/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/destinations/0/namespace
      value: dev
```

### Example 2: OneView Tenant (Jefferies Dev)

**Base**: `oneview/nonprod/argocd/base/`

**Overlay**: `oneview/nonprod/jefferies/dev/argocd/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../argocd/base

commonLabels:
  tenant: jefferies
  environment: dev

patches:
- target:
    kind: ApplicationSet
  patch: |-
    - op: replace
      path: /metadata/name
      value: jefferies-dev
    - op: replace
      path: /metadata/labels/tenant
      value: jefferies
    - op: replace
      path: /spec/template/metadata/name
      value: jefferies-{{index .path.segments 2}}-dev
    - op: replace
      path: /spec/template/spec/project
      value: jefferies-dev
    - op: replace
      path: /spec/template/spec/destination/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/template/spec/destination/namespace
      value: jefferies-dev
    - op: replace
      path: /spec/generators/0/git/directories/0/path
      value: argocd/apps/*/envs/dev

- target:
    kind: AppProject
  patch: |-
    - op: replace
      path: /metadata/name
      value: jefferies-dev
    - op: replace
      path: /metadata/labels/tenant
      value: jefferies
    - op: replace
      path: /spec/destinations/0/name
      value: spoke2.us-east-1.eksctl.io
    - op: replace
      path: /spec/destinations/0/namespace
      value: jefferies-dev
    - op: add
      path: /metadata/annotations
      value:
        aws-account-id: "123456789012"
```

## Testing Locally

Always test your Kustomize overlays locally before committing:

```bash
# Test Kynex dev overlay
kubectl kustomize kynex/nonprod/dev/argocd/

# Test OneView Jefferies dev overlay
kubectl kustomize oneview/nonprod/jefferies/dev/argocd/

# Verify specific fields
kubectl kustomize kynex/nonprod/dev/argocd/ | grep "name: kynex-dev"
kubectl kustomize kynex/nonprod/dev/argocd/ | grep "namespace: dev"
```

## Common Patterns

### Pattern 1: Simple Environment Name
Used by Kynex (pooled multi-tenant):
- Namespace: `dev`, `sit`, `prod`
- ApplicationSet: `kynex-dev`, `kynex-prod`

### Pattern 2: Tenant-Prefixed Namespace
Used by OneView (siloed per-tenant):
- Namespace: `jefferies-dev`, `ocbc-prod`
- ApplicationSet: `jefferies-dev`, `ocbc-prod`

### Pattern 3: Application Naming
- Kynex: `kynex-{service}-{environment}`
- OneView: `{tenant}-{service}-{environment}`

## Troubleshooting

### Issue: Kustomize build fails

**Solution**: Check that all field paths are correct. Use `kubectl kustomize` to see the error.

### Issue: Placeholder values not replaced

**Solution**: Ensure the patch operation is `replace` and the path matches exactly.

### Issue: Multiple resources affected

**Solution**: Use more specific target selectors:
```yaml
- target:
    kind: ApplicationSet
    name: specific-name
  patch: |-
    ...
```

## Best Practices

1. **Always test locally** before committing
2. **Use consistent naming** across environments
3. **Document custom fields** if you add new ones
4. **Keep patches minimal** - only replace what's necessary
5. **Use commonLabels** for labels that apply to all resources

## Reference

- [Kustomize Replacements Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/replacements/)
- [JSON Patch Specification](https://jsonpatch.com/)
