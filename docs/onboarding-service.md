# Service Onboarding Guide

This guide provides step-by-step instructions for adding a new microservice to the platform. Services are automatically discovered and deployed without platform team involvement.

## Overview

Adding a new service involves:
1. Creating base Kubernetes manifests
2. Creating environment-specific overlays
3. Committing to CDUsingArgoCD repository
4. Automatic discovery and deployment by Argo CD

**Time Required**: < 30 minutes  
**Platform Team Involvement**: None (fully automated)

## Prerequisites

- Git access to CDUsingArgoCD repository
- Basic understanding of Kubernetes manifests
- Basic understanding of Kustomize
- Service information:
  - Service name (e.g., `payment`, `notification`)
  - Container image and tag
  - Required environments (dev, sit, preprod, prod)
  - Resource requirements (CPU, memory)
  - Environment-specific configuration

## Repository Structure

Services in CDUsingArgoCD follow this structure:

```
CDUsingArgoCD/
└── argocd/
    └── apps/
        └── {service}/
            ├── base/
            │   ├── deployment.yaml
            │   ├── service.yaml
            │   └── kustomization.yaml
            └── envs/
                ├── dev/
                │   ├── kustomization.yaml
                │   └── deployment.yaml (patches)
                ├── sit/
                │   ├── kustomization.yaml
                │   └── deployment.yaml
                ├── preprod/
                │   ├── kustomization.yaml
                │   └── deployment.yaml
                └── prod/
                    ├── kustomization.yaml
                    └── deployment.yaml
```

## Step-by-Step Instructions

### Step 1: Create Base Manifests

Create the base folder and manifests:

```bash
cd CDUsingArgoCD
mkdir -p argocd/apps/payment/base
```

#### 1.1 Create Deployment

Create `argocd/apps/payment/base/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-deployment
  labels:
    app: payment
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
        image: myregistry/payment:1.0.0
        ports:
        - containerPort: 8080
          name: http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        env:
        - name: APP_NAME
          value: payment
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 1.2 Create Service

Create `argocd/apps/payment/base/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  labels:
    app: payment
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: payment
```

#### 1.3 Create Base Kustomization

Create `argocd/apps/payment/base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml

commonLabels:
  app: payment
  managed-by: argocd
```

### Step 2: Create Environment Overlays

#### 2.1 Create Dev Environment

Create `argocd/apps/payment/envs/dev/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

commonLabels:
  environment: dev

patchesStrategicMerge:
- deployment.yaml
```

Create `argocd/apps/payment/envs/dev/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: payment
        image: myregistry/payment:1.0.0-dev
        env:
        - name: ENVIRONMENT
          value: "dev"
        - name: LOG_LEVEL
          value: "debug"
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
```

#### 2.2 Create SIT Environment

Create `argocd/apps/payment/envs/sit/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

commonLabels:
  environment: sit

patchesStrategicMerge:
- deployment.yaml
```

Create `argocd/apps/payment/envs/sit/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-deployment
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: payment
        image: myregistry/payment:1.0.0-sit
        env:
        - name: ENVIRONMENT
          value: "sit"
        - name: LOG_LEVEL
          value: "info"
```

#### 2.3 Create Preprod Environment

Create `argocd/apps/payment/envs/preprod/` (similar to sit, adjust values).

#### 2.4 Create Prod Environment

Create `argocd/apps/payment/envs/prod/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

commonLabels:
  environment: prod

patchesStrategicMerge:
- deployment.yaml
```

Create `argocd/apps/payment/envs/prod/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-deployment
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: payment
        image: myregistry/payment:1.0.0
        env:
        - name: ENVIRONMENT
          value: "prod"
        - name: LOG_LEVEL
          value: "warn"
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 1Gi
```

### Step 3: Test Locally

Test each environment overlay:

```bash
# Test dev environment
kubectl kustomize argocd/apps/payment/envs/dev/

# Test sit environment
kubectl kustomize argocd/apps/payment/envs/sit/

# Test prod environment
kubectl kustomize argocd/apps/payment/envs/prod/

# Verify specific values
kubectl kustomize argocd/apps/payment/envs/dev/ | grep "replicas: 1"
kubectl kustomize argocd/apps/payment/envs/prod/ | grep "replicas: 3"
```

### Step 4: Commit and Push

```bash
git add argocd/apps/payment
git commit -m "Add payment service"
git push origin scalable
```

### Step 5: Verify Automatic Discovery

Wait 1-3 minutes for Argo CD to discover and deploy:

```bash
# Check if Applications were created
argocd app list | grep payment

# Expected output (for Kynex):
# kynex-payment-dev      ...
# kynex-payment-sit      ...
# kynex-payment-preprod  ...
# kynex-payment-prod     ...

# Expected output (for OneView Jefferies):
# jefferies-payment-dev  ...
# jefferies-payment-sit  ...
# jefferies-payment-preprod  ...
# jefferies-payment-prod ...

# Check deployment status
argocd app get kynex-payment-dev

# Check pods
kubectl get pods -n dev --context <spoke2-context> | grep payment
kubectl get pods -n prod --context <spoke1-context> | grep payment
```

## Advanced Patterns

### Pattern 1: Using ConfigMaps

Add to base:

```yaml
# argocd/apps/payment/base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-config
data:
  app.properties: |
    server.port=8080
    app.name=payment
```

Add to `base/kustomization.yaml`:
```yaml
resources:
- deployment.yaml
- service.yaml
- configmap.yaml
```

Override in environment:
```yaml
# argocd/apps/payment/envs/dev/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-config
data:
  app.properties: |
    server.port=8080
    app.name=payment
    log.level=debug
```

### Pattern 2: Using Secrets

```yaml
# argocd/apps/payment/base/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: payment-secret
type: Opaque
stringData:
  database-url: "postgres://localhost:5432/payment"
```

**Note**: In production, use external secret management (e.g., AWS Secrets Manager, HashiCorp Vault).

### Pattern 3: Using Helm Charts

If your service uses Helm:

```yaml
# argocd/apps/payment/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
- name: payment
  repo: https://charts.example.com
  version: 1.0.0
  releaseName: payment
  namespace: default
  valuesFile: values.yaml
```

Add `buildOptions: "--enable-helm"` to the ApplicationSet in gitops-demo.

### Pattern 4: Multiple Containers

```yaml
spec:
  template:
    spec:
      containers:
      - name: payment
        image: myregistry/payment:1.0.0
        ports:
        - containerPort: 8080
      - name: sidecar
        image: myregistry/sidecar:1.0.0
        ports:
        - containerPort: 9090
```

## Environment-Specific Configuration

### Resource Sizing Guidelines

| Environment | Replicas | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-------------|----------|-------------|----------------|-----------|--------------|
| Dev | 1 | 50m | 64Mi | 200m | 256Mi |
| SIT | 2 | 100m | 128Mi | 500m | 512Mi |
| Preprod | 2 | 200m | 256Mi | 1000m | 1Gi |
| Prod | 3+ | 200m | 256Mi | 2000m | 2Gi |

### Image Tag Strategy

- **Dev**: Use `-dev` suffix or `latest` for rapid iteration
- **SIT**: Use `-sit` suffix or specific version for testing
- **Preprod**: Use release candidate tags (e.g., `1.0.0-rc1`)
- **Prod**: Use stable version tags (e.g., `1.0.0`)

## Troubleshooting

### Issue: Service not discovered

**Check**: Verify folder structure matches the pattern
```bash
ls -la argocd/apps/payment/envs/dev/
# Should contain: kustomization.yaml
```

**Solution**: Ensure the path is exactly `argocd/apps/{service}/envs/{environment}/`

### Issue: Application created but not syncing

**Check**: Verify Kustomize build works
```bash
kubectl kustomize argocd/apps/payment/envs/dev/
```

**Solution**: Fix any Kustomize errors in the overlay.

### Issue: Pods not starting

**Check**: View Application details
```bash
argocd app get kynex-payment-dev
kubectl describe pod -n dev <pod-name>
```

**Solution**: Check image availability, resource limits, and configuration.

## Best Practices

1. **Start with base**: Define common configuration in base, override only what's different
2. **Use semantic versioning**: Tag images with proper versions
3. **Set resource limits**: Always define requests and limits
4. **Add health checks**: Include liveness and readiness probes
5. **Test locally**: Always test with `kubectl kustomize` before committing
6. **Use labels**: Add consistent labels for filtering and organization
7. **Document dependencies**: If service depends on others, document it
8. **Follow naming conventions**: Use consistent naming across all manifests

## Deployment Workflow

1. **Dev**: Commit to `scalable` branch → Auto-deploy to dev
2. **SIT**: Merge to `scalable` → Auto-deploy to sit
3. **Preprod**: Tag release → Auto-deploy to preprod
4. **Prod**: Promote tag → Auto-deploy to prod

## Next Steps

After onboarding a service:
1. Set up monitoring and alerting
2. Configure log aggregation
3. Set up CI/CD pipeline for image builds
4. Document service-specific runbooks
5. Configure backup and disaster recovery

## Support

For issues or questions:
- Platform team documentation: [README.md](../README.md)
- Kustomize guide: [kustomize-replacements.md](kustomize-replacements.md)
- Design document: `.kiro/specs/scalable-gitops-platform/design.md`
