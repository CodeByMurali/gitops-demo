# Tasks: Scalable GitOps Platform Architecture

## Overview

Implementation tasks for transforming the gitops-demo repository into a production-grade, scalable GitOps platform using Argo CD ApplicationSets and Kustomize.

**Branch**: All changes in `scalable` branch
**Target Clusters**: spoke1, spoke2 (registered with Argo CD on hub cluster)

---

## Phase 1: Foundation & Kynex Nonprod

### 1.1 Create Git Branch
- [x] 1.1.1 Create `scalable` branch in gitops-demo repository
- [x] 1.1.2 Create `scalable` branch in CDUsingArgoCD repository

### 1.2 Create Bootstrap Structure
- [x] 1.2.1 Create `bootstrap/` folder at repository root
- [x] 1.2.2 Create `bootstrap/kynex-nonprod-bootstrap.yaml`
- [x] 1.2.3 Create `bootstrap/kynex-prod-bootstrap.yaml`
- [x] 1.2.4 Create `bootstrap/oneview-nonprod-bootstrap.yaml`
- [x] 1.2.5 Create `bootstrap/oneview-prod-bootstrap.yaml`

### 1.3 Create Kynex Nonprod Base
- [x] 1.3.1 Create `kynex/nonprod/base/` folder
- [x] 1.3.2 Create `kynex/nonprod/base/applicationset.yaml` with placeholders
- [x] 1.3.3 Create `kynex/nonprod/base/appproject.yaml` with restricted permissions
- [x] 1.3.4 Create `kynex/nonprod/base/kustomization.yaml`

### 1.4 Create Kynex Nonprod Dev Overlay
- [x] 1.4.1 Create `kynex/nonprod/dev/argocd/` folder
- [x] 1.4.2 Create `kynex/nonprod/dev/argocd/kustomization.yaml` with replacements
- [x] 1.4.3 Configure cluster name: `spoke2.us-east-1.eksctl.io`
- [x] 1.4.4 Configure namespace: `dev`
- [x] 1.4.5 Test Kustomize build locally

### 1.5 Create Kynex Nonprod SIT Overlay
- [x] 1.5.1 Create `kynex/nonprod/sit/argocd/` folder
- [x] 1.5.2 Create `kynex/nonprod/sit/argocd/kustomization.yaml` with replacements
- [x] 1.5.3 Configure cluster name: `spoke2.us-east-1.eksctl.io`
- [x] 1.5.4 Configure namespace: `sit`
- [x] 1.5.5 Test Kustomize build locally

### 1.6 Test Kynex Nonprod Bootstrap
- [x] 1.6.1 Apply `bootstrap/kynex-nonprod-bootstrap.yaml` to hub cluster
- [x] 1.6.2 Verify bootstrap ApplicationSet is created
- [x] 1.6.3 Verify bootstrap discovers dev and sit folders
- [x] 1.6.4 Verify ApplicationSets `kynex-dev` and `kynex-sit` are created
- [x] 1.6.5 Verify AppProjects `kynex-dev` and `kynex-sit` are created
- [x] 1.6.6 Verify ApplicationSets discover services in CDUsingArgoCD
- [x] 1.6.7 Verify Applications are created (e.g., `kynex-marketrisk-dev`)
- [x] 1.6.8 Verify services are deployed to spoke2 cluster

---

## Phase 2: Kynex Prod

### 2.1 Create Kynex Prod Base
- [x] 2.1.1 Create `kynex/prod/base/` folder
- [x] 2.1.2 Create `kynex/prod/base/applicationset.yaml` (copy from nonprod, adjust labels)
- [x] 2.1.3 Create `kynex/prod/base/appproject.yaml` (copy from nonprod, adjust labels)
- [x] 2.1.4 Create `kynex/prod/base/kustomization.yaml`

### 2.2 Create Kynex Prod Preprod Overlay
- [x] 2.2.1 Create `kynex/prod/preprod/argocd/` folder
- [x] 2.2.2 Create `kynex/prod/preprod/argocd/kustomization.yaml` with replacements
- [x] 2.2.3 Configure cluster name: `spoke1.us-east-1.eksctl.io`
- [x] 2.2.4 Configure namespace: `preprod`
- [x] 2.2.5 Test Kustomize build locally

### 2.3 Create Kynex Prod Prod Overlay
- [x] 2.3.1 Create `kynex/prod/prod/argocd/` folder
- [x] 2.3.2 Create `kynex/prod/prod/argocd/kustomization.yaml` with replacements
- [x] 2.3.3 Configure cluster name: `spoke1.us-east-1.eksctl.io`
- [x] 2.3.4 Configure namespace: `prod`
- [x] 2.3.5 Test Kustomize build locally

### 2.4 Test Kynex Prod Bootstrap
- [ ] 2.4.1 Apply `bootstrap/kynex-prod-bootstrap.yaml` to hub cluster
- [ ] 2.4.2 Verify bootstrap ApplicationSet is created
- [ ] 2.4.3 Verify ApplicationSets `kynex-preprod` and `kynex-prod` are created
- [ ] 2.4.4 Verify AppProjects are created with restricted permissions
- [ ] 2.4.5 Verify services are deployed to spoke1 cluster

---

## Phase 3: OneView Nonprod

### 3.1 Fix Naming Inconsistency
- [ ] 3.1.1 Rename `oneview/prod/jeffries/` to `oneview/prod/jefferies/`
- [ ] 3.1.2 Update any references to "jeffries" in existing files

### 3.2 Create OneView Nonprod Base
- [ ] 3.2.1 Create `oneview/nonprod/base/` folder
- [ ] 3.2.2 Create `oneview/nonprod/base/applicationset.yaml` with tenant support
- [ ] 3.2.3 Create `oneview/nonprod/base/appproject.yaml` with restricted permissions
- [ ] 3.2.4 Create `oneview/nonprod/base/kustomization.yaml`

### 3.3 Create Jefferies Nonprod Overlays
- [ ] 3.3.1 Create `oneview/nonprod/jefferies/poc/argocd/kustomization.yaml`
- [ ] 3.3.2 Configure cluster: `spoke2.us-east-1.eksctl.io`, namespace: `poc`
- [ ] 3.3.3 Create `oneview/nonprod/jefferies/dev/argocd/kustomization.yaml`
- [ ] 3.3.4 Configure cluster: `spoke2.us-east-1.eksctl.io`, namespace: `dev`
- [ ] 3.3.5 Create `oneview/nonprod/jefferies/sit/argocd/kustomization.yaml`
- [ ] 3.3.6 Configure cluster: `spoke2.us-east-1.eksctl.io`, namespace: `sit`
- [ ] 3.3.7 Add AWS account ID annotation to all Jefferies overlays

### 3.4 Create OCBC Nonprod Overlays
- [ ] 3.4.1 Create `oneview/nonprod/ocbc/dev/argocd/kustomization.yaml`
- [ ] 3.4.2 Configure cluster: `spoke2.us-east-1.eksctl.io`, namespace: `dev`
- [ ] 3.4.3 Create `oneview/nonprod/ocbc/sit/argocd/kustomization.yaml`
- [ ] 3.4.4 Configure cluster: `spoke2.us-east-1.eksctl.io`, namespace: `sit`
- [ ] 3.4.5 Add AWS account ID annotation to all OCBC overlays

### 3.5 Test OneView Nonprod Bootstrap
- [ ] 3.5.1 Apply `bootstrap/oneview-nonprod-bootstrap.yaml` to hub cluster
- [ ] 3.5.2 Verify ApplicationSets for Jefferies (poc, dev, sit) are created
- [ ] 3.5.3 Verify ApplicationSets for OCBC (dev, sit) are created
- [ ] 3.5.4 Verify AppProjects have correct permissions and AWS account annotations
- [ ] 3.5.5 Verify services are deployed to spoke2 cluster in correct namespaces

---

## Phase 4: OneView Prod

### 4.1 Create OneView Prod Base
- [ ] 4.1.1 Create `oneview/prod/base/` folder
- [ ] 4.1.2 Create `oneview/prod/base/applicationset.yaml`
- [ ] 4.1.3 Create `oneview/prod/base/appproject.yaml`
- [ ] 4.1.4 Create `oneview/prod/base/kustomization.yaml`

### 4.2 Create Jefferies Prod Overlays
- [ ] 4.2.1 Create `oneview/prod/jefferies/preprod/argocd/kustomization.yaml`
- [ ] 4.2.2 Configure cluster: `spoke1.us-east-1.eksctl.io`, namespace: `preprod`
- [ ] 4.2.3 Create `oneview/prod/jefferies/prod/argocd/kustomization.yaml`
- [ ] 4.2.4 Configure cluster: `spoke1.us-east-1.eksctl.io`, namespace: `prod`
- [ ] 4.2.5 Add AWS account ID annotation

### 4.3 Create OCBC Prod Overlays
- [ ] 4.3.1 Create `oneview/prod/ocbc/preprod/argocd/kustomization.yaml`
- [ ] 4.3.2 Configure cluster: `spoke1.us-east-1.eksctl.io`, namespace: `preprod`
- [ ] 4.3.3 Create `oneview/prod/ocbc/prod/argocd/kustomization.yaml`
- [ ] 4.3.4 Configure cluster: `spoke1.us-east-1.eksctl.io`, namespace: `prod`
- [ ] 4.3.5 Add AWS account ID annotation

### 4.4 Test OneView Prod Bootstrap
- [ ] 4.4.1 Apply `bootstrap/oneview-prod-bootstrap.yaml` to hub cluster
- [ ] 4.4.2 Verify all ApplicationSets are created
- [ ] 4.4.3 Verify services are deployed to spoke1 cluster

---

## Phase 5: Platform Services

### 5.1 Create Kynex Nonprod Platform Service
- [ ] 5.1.1 Create `kynex/nonprod/platform/nginx-ingress/argocd/` folder
- [ ] 5.1.2 Create `nginx-ingress-app.yaml` (Argo CD Application)
- [ ] 5.1.3 Configure Helm chart: `ingress-nginx` version 4.8.3
- [ ] 5.1.4 Configure destination: spoke2 cluster, `ingress-nginx` namespace
- [ ] 5.1.5 Create `kustomization.yaml`
- [ ] 5.1.6 Test deployment

### 5.2 Create Kynex Prod Platform Service
- [ ] 5.2.1 Create `kynex/prod/platform/nginx-ingress/argocd/` folder
- [ ] 5.2.2 Create `nginx-ingress-app.yaml`
- [ ] 5.2.3 Configure destination: spoke1 cluster
- [ ] 5.2.4 Create `kustomization.yaml`
- [ ] 5.2.5 Test deployment

### 5.3 Create OneView Nonprod Platform Service
- [ ] 5.3.1 Create `oneview/nonprod/platform/nginx-ingress/argocd/` folder
- [ ] 5.3.2 Create `nginx-ingress-app.yaml`
- [ ] 5.3.3 Configure destination: spoke2 cluster
- [ ] 5.3.4 Create `kustomization.yaml`
- [ ] 5.3.5 Test deployment

### 5.4 Create OneView Prod Platform Service
- [ ] 5.4.1 Create `oneview/prod/platform/nginx-ingress/argocd/` folder
- [ ] 5.4.2 Create `nginx-ingress-app.yaml`
- [ ] 5.4.3 Configure destination: spoke1 cluster
- [ ] 5.4.4 Create `kustomization.yaml`
- [ ] 5.4.5 Test deployment

---

## Phase 6: Documentation

### 6.1 Create Main README
- [ ] 6.1.1 Document repository structure
- [ ] 6.1.2 Explain 3-layer architecture (Bootstrap → ApplicationSets → Applications)
- [ ] 6.1.3 Document Kustomize base/overlay pattern
- [ ] 6.1.4 Provide quick start guide
- [ ] 6.1.5 Include cluster information (hub, spoke1, spoke2)

### 6.2 Create Kustomize Replacements Guide
- [ ] 6.2.1 Create `docs/kustomize-replacements.md`
- [ ] 6.2.2 Explain how replacements work
- [ ] 6.2.3 Document all supported replacement fields
- [ ] 6.2.4 Provide examples for each field
- [ ] 6.2.5 Show how to test locally with `kubectl kustomize`

### 6.3 Create Tenant Onboarding Guide
- [ ] 6.3.1 Create `docs/onboarding-tenant.md`
- [ ] 6.3.2 Step-by-step instructions for adding new tenant
- [ ] 6.3.3 Include folder structure to create
- [ ] 6.3.4 Include kustomization.yaml template
- [ ] 6.3.5 Include verification steps

### 6.4 Create Service Onboarding Guide
- [ ] 6.4.1 Create `docs/onboarding-service.md`
- [ ] 6.4.2 Explain CDUsingArgoCD repository structure
- [ ] 6.4.3 Show how to create base manifests
- [ ] 6.4.4 Show how to create environment overlays
- [ ] 6.4.5 Explain automatic discovery process

---

## Phase 7: Testing & Validation

### 7.1 End-to-End Testing
- [ ] 7.1.1 Test bootstrap on fresh cluster
- [ ] 7.1.2 Verify all ApplicationSets are created
- [ ] 7.1.3 Verify all AppProjects are created
- [ ] 7.1.4 Verify all services are discovered and deployed
- [ ] 7.1.5 Verify platform services (nginx-ingress) are deployed

### 7.2 Workflow Testing
- [ ] 7.2.1 Test adding new microservice to CDUsingArgoCD
- [ ] 7.2.2 Verify automatic discovery and deployment
- [ ] 7.2.3 Test changing platform-wide sync policy
- [ ] 7.2.4 Verify change propagates to all environments
- [ ] 7.2.5 Test adding new tenant (e.g., HSBC)
- [ ] 7.2.6 Verify tenant isolation

### 7.3 Security Validation
- [ ] 7.3.1 Verify AppProjects have restricted permissions
- [ ] 7.3.2 Verify no cluster-wide resources allowed
- [ ] 7.3.3 Verify prod/nonprod isolation
- [ ] 7.3.4 Verify tenant isolation in OneView

### 7.4 Duplication Analysis
- [ ] 7.4.1 Count lines of code in bases
- [ ] 7.4.2 Count lines of code in overlays
- [ ] 7.4.3 Calculate duplication percentage
- [ ] 7.4.4 Verify < 10% duplication target is met

---

## Phase 8: Cleanup & Migration

### 8.1 Remove Old Files
- [ ] 8.1.1 Remove old ApplicationSet files from environment folders
- [ ] 8.1.2 Remove old AppProject files from environment folders
- [ ] 8.1.3 Keep `services/manifest.yml` files (used for other purposes)

### 8.2 Update CDUsingArgoCD Repository
- [ ] 8.2.1 Ensure all services follow `argocd/apps/{service}/envs/{env}` pattern
- [ ] 8.2.2 Verify Kustomize bases exist for all services
- [ ] 8.2.3 Verify environment overlays exist for all services

### 8.3 Final Verification
- [ ] 8.3.1 Verify all Applications are healthy
- [ ] 8.3.2 Verify all ApplicationSets are synced
- [ ] 8.3.3 Verify no orphaned resources
- [ ] 8.3.4 Verify Argo CD UI shows correct hierarchy

---

## Success Criteria

- [ ] ✅ All 4 bootstrap ApplicationSets deployed and working
- [ ] ✅ All environment ApplicationSets auto-discovered and deployed
- [ ] ✅ All services auto-discovered from CDUsingArgoCD
- [ ] ✅ Platform services (nginx-ingress) deployed to all clusters
- [ ] ✅ Configuration duplication < 10%
- [ ] ✅ New tenant onboarding takes < 1 hour
- [ ] ✅ New service onboarding requires no platform team involvement
- [ ] ✅ Platform-wide changes propagate automatically
- [ ] ✅ Documentation complete and accurate
- [ ] ✅ All tests passing

---

## Notes

**Cluster Mapping**:
- Hub: `hub.us-east-1.eksctl.io` (Argo CD installed)
- Spoke1: `spoke1.us-east-1.eksctl.io` (Prod realm)
- Spoke2: `spoke2.us-east-1.eksctl.io` (Nonprod realm)

**Branch Strategy**:
- All changes in `scalable` branch
- Test in nonprod first
- Promote to prod after validation

**Testing Commands**:
```bash
# Test Kustomize build
kubectl kustomize kynex/nonprod/dev/argocd/

# Apply bootstrap
kubectl apply -f bootstrap/kynex-nonprod-bootstrap.yaml

# Check ApplicationSets
kubectl get applicationsets -n argocd

# Check Applications
argocd app list

# Check clusters
argocd cluster list
```
