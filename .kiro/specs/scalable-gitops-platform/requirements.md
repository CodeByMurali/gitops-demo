# Requirements: Scalable GitOps Platform Architecture

## 1. Problem Statement

The gitops-demo repository currently lacks a scalable, production-grade structure for managing multiple deployment models, tenants, and environments. There is no centralized configuration management, leading to duplication and maintenance challenges. The platform needs to support two distinct deployment models (Kynex pooled multi-tenant and OneView siloed per-tenant) with proper governance, blast-radius control, and centralized change propagation.

## 2. Goals and Objectives

Transform the gitops-demo repository into a production-grade, scalable GitOps platform that:
- Supports two deployment models with clear separation and governance
- Enables automatic service discovery without manual configuration
- Minimizes configuration duplication through centralized management
- Provides fast tenant and environment onboarding
- Enforces security isolation between prod and nonprod realms
- Maintains clear audit trails through Git-based workflows

This platform repository manages Argo CD ApplicationSets and AppProjects that discover and deploy microservices from the CDUsingArgoCD application repository. The application repository contains Kustomize-based service definitions following the base/overlay pattern.

## 3. Repository Context

### 3.1 Repository Responsibilities

**gitops-demo (Platform Repository)**:
- Argo CD ApplicationSets for service discovery
- Argo CD AppProjects for RBAC and governance
- Bootstrap ApplicationSets for cluster initialization
- Kustomize bases and overlays for ApplicationSet configuration
- Platform-wide policies and standards

**CDUsingArgoCD (Application Repository)**:
- Microservice Kubernetes manifests (Deployment, Service, etc.)
- Kustomize bases in `argocd/apps/{service}/base/`
- Environment overlays in `argocd/apps/{service}/envs/{environment}/`
- Helm chart references (for services using Helm)
- Application-specific configuration

### 3.2 Current Application Services

The CDUsingArgoCD repository contains these sample microservices:
- `marketrisk` - Kustomize-based service (dev, qa environments)
- `trade` - Kustomize-based service
- `ref` - Kustomize-based service  
- `ms1`, `ms2`, `ms3` - Generic microservices
- `helmapp` - Helm-based service (dev, qa environments)
- `helmovapp` - Helm-based service (prod environment)

All services follow the pattern: `argocd/apps/{service}/envs/{environment}/`

## 4. User Stories and Acceptance Criteria

### 4.1 Platform Engineer Stories

**US-2.1.1: As a Platform Engineer, I need to bootstrap a new EKS cluster with all ApplicationSets and AppProjects so that it's production-ready without manual configuration.**

Acceptance Criteria:
- Single root ApplicationSet can bootstrap entire cluster
- All environment-level ApplicationSets are automatically discovered and deployed
- AppProjects are created with proper RBAC boundaries
- Cluster-specific configuration is externalized

**US-2.1.2: As a Platform Engineer, I need to apply a platform-wide change (labels, annotations, sync policies) once and have it propagate to all relevant environments so that I don't duplicate configuration across 20+ ApplicationSet files.**

Acceptance Criteria:
- Shared configuration exists at realm level using Kustomize bases
- Environment-specific overrides are possible via Kustomize overlays
- Changes to base configuration automatically affect all child environments
- Clear inheritance hierarchy is documented

**US-2.1.3: As a Platform Engineer, I need clear separation between Kynex (pooled) and OneView (siloed) deployment models so that each can evolve independently.**

Acceptance Criteria:
- Separate ApplicationSet hierarchies for Kynex and OneView
- Separate AppProjects enforce isolation
- Shared patterns are reusable via Kustomize components
- Documentation clearly defines ownership

**US-2.1.4: As a Platform Engineer, I need to onboard a new tenant (e.g., HSBC) to OneView without modifying existing tenant configurations so that blast radius is contained.**

Acceptance Criteria:
- Create new tenant folder structure
- Copy and customize tenant-specific Kustomize overlays
- No changes to existing tenants required
- Onboarding takes < 1 hour

### 4.2 Application Team Stories

**US-2.2.1: As an Application Team, I need to add a new microservice to the CDUsingArgoCD repository and have it automatically discovered by Argo CD so that I don't need platform team involvement.**

Acceptance Criteria:
- ApplicationSets use Git Directory Generator to discover services
- Services follow standard structure: `argocd/apps/{service}/envs/{environment}`
- No manual ApplicationSet modification required
- Service appears in Argo CD UI within sync interval

**US-2.2.2: As an Application Team, I need environment-specific configuration for my service using Kustomize overlays so that I can customize per environment.**

Acceptance Criteria:
- Base manifests in `argocd/apps/{service}/base/`
- Environment overlays in `argocd/apps/{service}/envs/{environment}/`
- Platform-enforced labels/annotations are inherited
- Clear documentation on Kustomize patterns

### 4.3 Security/Compliance Stories

**US-2.3.1: As a Security Engineer, I need to ensure that prod and nonprod realms are completely isolated so that a nonprod incident cannot affect production.**

Acceptance Criteria:
- Separate AppProjects for prod and nonprod
- Separate AWS accounts/EKS clusters
- No cross-realm dependencies
- Audit trail for all changes via Git history

**US-2.3.2: As a Compliance Officer, I need to enforce mandatory labels (cost-center, owner, environment, tenant) on all Argo CD Applications so that we can track costs and ownership.**

Acceptance Criteria:
- Labels are defined in Kustomize bases at realm level
- All ApplicationSets inherit and apply these labels
- Labels cannot be overridden by tenants
- Validation prevents deployment without required labels

## 5. Functional Requirements

### 5.1 Repository Structure

**FR-5.1.1: The repository MUST maintain the mandated folder structure:**
```
kynex/                           # Pooled multi-tenant deployment model
  nonprod/                       # Non-production realm
    dev/                         # Development environment
      argocd/                    # Argo CD manifests for this environment
    sit/                         # System integration test environment
      argocd/
  prod/                          # Production realm
    preprod/                     # Pre-production environment
      argocd/
    prod/                        # Production environment
      argocd/

oneview/                         # Siloed per-tenant deployment model
  nonprod/                       # Non-production realm
    jefferies/                   # Tenant: Jefferies
      poc/                       # Proof of concept environment
        argocd/
      dev/                       # Development environment
        argocd/
      sit/                       # System integration test environment
        argocd/
    ocbc/                        # Tenant: OCBC
      dev/
        argocd/
      sit/
        argocd/
  prod/                          # Production realm
    jefferies/                   # Tenant: Jefferies
      preprod/                   # Pre-production environment
        argocd/
      prod/                      # Production environment
        argocd/
    ocbc/                        # Tenant: OCBC
      preprod/
        argocd/
      prod/
        argocd/
```

**FR-5.1.2: Argo CD manifests MUST be organized using Kustomize:**
- Base ApplicationSets and AppProjects at realm level
- Environment-specific overlays at environment level
- Bootstrap ApplicationSets at repository root
- NO ConfigMaps for configuration management

**FR-5.1.3: The `services/manifest.yml` files MUST be ignored:**
- These files serve a different purpose unrelated to Argo CD
- Do not reference or modify them
- Do not use them for configuration

### 5.2 Centralized Configuration & Inheritance

**FR-5.2.1: Shared configuration MUST be defined using Kustomize bases:**
- Deployment model level (kynex/, oneview/): Model-specific bases
- Realm level (nonprod/, prod/): Realm-specific bases
- Environment level (dev/, sit/, etc.): Environment-specific overlays

**FR-5.2.2: Configuration inheritance MUST follow Kustomize overlay pattern:**
1. Base ApplicationSet/AppProject templates at realm level
2. Environment overlays reference bases and add/override specific fields
3. Common labels, annotations, sync policies defined in bases
4. Environment-specific values (cluster names, namespaces) in overlays

**FR-5.2.3: Kustomize bases MUST contain:**
- ApplicationSet templates with placeholders
- AppProject templates with common RBAC rules
- Common labels and annotations
- Standard sync policies (automated, prune, selfHeal)
- Health checks and retry logic

### 5.3 ApplicationSet Strategy

**FR-5.3.1: Use Git Directory Generator for service discovery:**
- ApplicationSets scan CDUsingArgoCD repository for services
- Pattern: `argocd/apps/*/envs/{environment}`
- Automatically discover new services without manual updates
- Support both Kustomize and Helm-based services

**FR-5.3.2: ApplicationSet naming convention:**
- Kynex: `{deployment-model}-{environment}` (e.g., kynex-dev)
- OneView: `{tenant}-{environment}` (e.g., jefferies-dev)

**FR-5.3.3: Generated Application naming convention:**
- Kynex: `{deployment-model}-{service}-{environment}` (e.g., kynex-marketrisk-dev)
- OneView: `{tenant}-{service}-{environment}` (e.g., jefferies-marketrisk-dev)

**FR-5.3.4: ApplicationSets MUST be separate per environment:**
- One ApplicationSet per environment (not one for all environments)
- Enables environment-specific configuration
- Reduces blast radius of changes
- Simplifies troubleshooting

### 5.4 AppProject Strategy

**FR-5.4.1: AppProjects MUST enforce least-privilege access:**
- One AppProject per environment
- Restrict source repositories (CDUsingArgoCD, gitops-demo)
- Restrict destination clusters and namespaces
- Define allowed resource types (initially allow all for PoC)

**FR-5.4.2: AppProject naming convention:**
- Kynex: `{deployment-model}-{environment}` (e.g., kynex-dev)
- OneView: `{tenant}-{environment}` (e.g., jefferies-dev)

**FR-5.4.3: AppProjects MUST be scoped by:**
- Deployment model (Kynex vs OneView)
- Realm (prod vs nonprod)
- Tenant (OneView only)
- Environment (dev, sit, preprod, prod)

### 5.5 Bootstrap & Root ApplicationSets

**FR-5.5.1: Root-level bootstrap ApplicationSets MUST:**
- Discover and deploy all environment-level ApplicationSets and AppProjects
- Use Git Directory Generator to find `argocd/` folders
- Be idempotent and self-healing
- Support both Kynex and OneView models

**FR-5.5.2: Bootstrap structure:**
```
bootstrap/
  kynex-bootstrap-appset.yaml       # Discovers all kynex ApplicationSets
  oneview-bootstrap-appset.yaml     # Discovers all oneview ApplicationSets
```

**FR-5.5.3: Bootstrap ApplicationSets MUST:**
- Scan gitops-demo repository for `*/argocd/` directories
- Generate Applications that deploy ApplicationSets and AppProjects
- Use appropriate labels for filtering (deployment-model, realm, tenant)

### 5.6 Application Repository Integration

**FR-5.6.1: ApplicationSets MUST reference CDUsingArgoCD repository:**
- Repository URL: `https://github.com/CodeByMurali/CDUsingArgoCD.git`
- Branch: `scalable` (for new changes)
- Path pattern: `argocd/apps/*/envs/{environment}`

**FR-5.6.2: Support both Kustomize and Helm services:**
- Kustomize services: Use `kustomize.enableHelm: true` for Helm chart support
- Helm services: Kustomize will process helmCharts directive
- No special handling required in ApplicationSet

**FR-5.6.3: All tenants share the same application repository (PoC):**
- Kynex, Jefferies, and OCBC all reference CDUsingArgoCD
- In production, each would have separate repositories
- ApplicationSets filter services by environment only

## 6. Non-Functional Requirements

### 6.1 Scalability

**NFR-6.1.1: The platform MUST support:**
- 10+ tenants in OneView
- 50+ microservices per tenant
- 5+ environments per tenant
- 100+ total Argo CD Applications

**NFR-6.1.2: Adding a new tenant MUST require:**
- Creating tenant folder structure
- Copying and customizing Kustomize overlays
- NO changes to existing tenants or shared bases

**NFR-6.1.3: Adding a new environment MUST require:**
- Creating environment folder with Kustomize overlay
- Referencing appropriate base
- NO changes to other environments

### 6.2 Maintainability

**NFR-6.2.1: Configuration duplication MUST be minimized:**
- DRY principle applied via Kustomize bases and overlays
- Shared configuration in bases (realm level)
- Environment-specific values in overlays only
- Target < 10% duplication across all manifests

**NFR-6.2.2: Changes MUST be traceable:**
- Git commit history shows what changed and why
- Argo CD UI shows sync status and drift
- All changes go through Git (no manual kubectl apply)

**NFR-6.2.3: Documentation MUST be clear:**
- README explains folder structure and inheritance
- Examples show how to add new tenant/environment
- Diagrams illustrate ApplicationSet hierarchy

### 6.3 Security

**NFR-6.3.1: Prod and nonprod MUST be isolated:**
- Separate AWS accounts (assumed, not in scope)
- Separate EKS clusters
- Separate Argo CD AppProjects
- No shared credentials

**NFR-6.3.2: Secrets MUST NOT be stored in Git:**
- Use AWS Secrets Manager or External Secrets Operator (future)
- Reference secrets by name/ARN only
- No plaintext secrets in any repository

**NFR-6.3.3: RBAC MUST be enforced:**
- AppProjects define allowed source repos
- AppProjects define allowed destination clusters/namespaces
- AppProjects define allowed resource types

### 6.4 Operability

**NFR-6.4.1: Platform engineers MUST be able to:**
- Bootstrap a new cluster in < 30 minutes
- Onboard a new tenant in < 1 hour
- Apply platform-wide changes in < 15 minutes

**NFR-6.4.2: Application teams MUST be able to:**
- Deploy a new service without platform team involvement
- Promote code through environments via Git commits to CDUsingArgoCD
- Rollback deployments via Git reverts

**NFR-6.4.3: Troubleshooting MUST be straightforward:**
- Argo CD UI shows clear Application hierarchy
- Labels enable filtering by tenant, environment, service
- Sync errors are visible and actionable

## 7. Constraints

### 7.1 Technical Constraints

**C-7.1.1: The mandated folder structure CANNOT be changed.**

**C-7.1.2: Application Helm charts and Kustomize templates live in CDUsingArgoCD repository.**

**C-7.1.3: Current cluster names (spoke2.us-east-1.eksctl.io) are PoC-only and will change.**

**C-7.1.4: DO NOT use ConfigMaps for configuration management.**

**C-7.1.5: DO NOT modify or reference `services/manifest.yml` files.**

**C-7.1.6: Use Kustomize for all configuration management in gitops-demo.**

**C-7.1.7: Use separate ApplicationSets per environment (not one for all).**

### 7.2 Organizational Constraints

**C-7.2.1: Platform team owns:**
- gitops-demo repository
- Argo CD installation and configuration
- ApplicationSets and AppProjects
- Governance policies and standards

**C-7.2.2: Application teams own:**
- CDUsingArgoCD repository
- Application Helm charts / Kustomize templates
- Application-specific configuration
- Service deployment manifests

### 7.3 Branching Constraints

**C-7.3.1: All changes MUST be made in the `scalable` branch:**
- gitops-demo repository: `scalable` branch
- CDUsingArgoCD repository: `scalable` branch

**C-7.3.2: Promotion workflow:**
- Commit changes to nonprod environments first
- Test and validate in nonprod
- Merge to prod environments after validation
- Use Git history for audit trail

### 7.4 Naming Constraints

**C-7.4.1: Standardize tenant name to `jefferies` everywhere:**
- Fix typo: `jeffries` → `jefferies` in prod folder
- Ensure consistency across all manifests

## 8. Assumptions

**A-8.1: Argo CD is installed in the `argocd` namespace on each cluster.**

**A-8.2: Each EKS cluster has network connectivity to GitHub.**

**A-8.3: AWS IAM roles for service accounts (IRSA) are configured for cross-account access (future).**

**A-8.4: Application teams follow naming conventions in CDUsingArgoCD repository.**

**A-8.5: All tenants share the same CDUsingArgoCD repository (PoC only).**

**A-8.6: Services in CDUsingArgoCD follow the pattern: `argocd/apps/{service}/envs/{environment}`.**

## 9. Out of Scope

**OS-9.1: EKS cluster provisioning (handled by Terraform/Pulumi/Crossplane).**

**OS-9.2: CI/CD pipelines for building container images.**

**OS-9.3: Application-level monitoring and alerting (tenant responsibility).**

**OS-9.4: Disaster recovery and backup strategies.**

**OS-9.5: Complex platform services (monitoring, logging, security tools).**
- Include a simple platform service (nginx-ingress) as proof of concept
- Complex platform services (Prometheus, Grafana, etc.) can be added later following the same pattern

**OS-9.6: Secrets management (AWS Secrets Manager, External Secrets Operator).**

**OS-9.7: Network policies and service mesh configuration.**

## 10. Success Criteria

The platform is considered successful when:

1. **DRY Configuration**: < 10% duplication across all ApplicationSet and AppProject manifests
2. **Automatic Discovery**: New services in CDUsingArgoCD appear in Argo CD without manual changes
3. **Fast Onboarding**: New tenant onboarding takes < 1 hour
4. **Centralized Changes**: Platform-wide label change requires editing only base files
5. **Clear Hierarchy**: Bootstrap → Environment ApplicationSets → Service Applications
6. **Isolation**: Prod and nonprod use separate AppProjects with no cross-realm access
7. **Consistency**: All environments follow the same Kustomize base/overlay pattern
8. **Scalability**: Adding 10th tenant is as easy as adding the 2nd tenant

## 11. Design Decisions (Confirmed)

**D-11.1: Kustomize Structure**
- Keep Kynex and OneView completely separate (no shared Kustomize components)
- Each deployment model has its own bases and overlays
- Duplication is acceptable for clarity and independence

**D-11.2: Bootstrap ApplicationSets**
- Four separate bootstrap ApplicationSets:
  - `bootstrap/kynex-nonprod-bootstrap.yaml`
  - `bootstrap/kynex-prod-bootstrap.yaml`
  - `bootstrap/oneview-nonprod-bootstrap.yaml`
  - `bootstrap/oneview-prod-bootstrap.yaml`
- Each bootstrap discovers and deploys ApplicationSets/AppProjects for its realm
- Clear separation between deployment models and realms

**D-11.3: Cluster Name Parameterization**
- Use Kustomize replacements to parameterize cluster names
- Each environment overlay defines its target cluster via replacements
- Documentation explains how to provide cluster names during deployment
- Example: `kustomization.yaml` with `replacements:` section

**D-11.4: AppProject Permissions**
- Start with restricted permissions (not wildcards)
- Allow only: Deployment, Service, ConfigMap, Secret, Ingress, HorizontalPodAutoscaler
- Namespace-scoped resources only (no cluster-wide resources initially)
- Document that production should further restrict based on needs

**D-11.5: Platform Service Proof of Concept**
- Include nginx-ingress as a simple platform service example
- Demonstrates pattern for platform-owned services
- Lives in separate folder structure (e.g., `kynex/nonprod/platform/`)
- Uses same ApplicationSet pattern as tenant applications

## 12. Open Questions

**Q-12.1: Platform Service Folder Structure**
Where should platform services live?
- Option A: Separate `platform/` folder at realm level (e.g., `kynex/nonprod/platform/nginx-ingress/`)
- Option B: Alongside environment folders (e.g., `kynex/nonprod/nginx-ingress/`)
- Option C: In a dedicated `platform-services/` folder at root level

**Decision**: Option A - Separate `platform/` folder for clear separation from tenant environments.

**Q-12.2: Platform Service Deployment Scope**
Should nginx-ingress be deployed:
- Option A: Once per realm (shared across all environments in that realm)
- Option B: Once per environment (separate ingress per dev, sit, etc.)
- Option C: Once per cluster (if multiple environments share a cluster)

**Decision**: Option C - Once per cluster, which aligns with typical ingress controller usage.

**Q-12.3: Platform Service Repository**
Where should nginx-ingress manifests live?
- Option A: In CDUsingArgoCD repository alongside application services
- Option B: In gitops-demo repository (inline manifests)
- Option C: In a separate platform-services repository

**Decision**: Option B - Inline in gitops-demo for simplicity, using Helm chart reference.

**Q-12.4: Environment-Specific Overrides**
For Kustomize replacements, should we support:
- Option A: Only cluster name replacement
- Option B: Cluster name + namespace + AWS account ID
- Option C: Fully parameterized (any field can be replaced)

**Decision**: Option B - Cluster name, namespace, and AWS account ID (for OneView tenants).

**Q-12.5: AppProject Source Repositories**
Should AppProjects allow:
- Option A: Only CDUsingArgoCD repository
- Option B: CDUsingArgoCD + gitops-demo repositories
- Option C: Any repository (wildcard)

**Decision**: Option B - Both repositories, since platform services may reference gitops-demo.

**Q-12.6: Namespace Strategy**
For Kynex (pooled multi-tenant):
- Option A: One namespace per environment (e.g., `dev` namespace contains all services)
- Option B: One namespace per service per environment (e.g., `dev-marketrisk`, `dev-trade`)
- Option C: One namespace per tenant per environment (but Kynex doesn't have tenants)

**Decision**: Option A - One namespace per environment for simplicity in pooled model.

For OneView (siloed per-tenant):
- Option A: One namespace per environment (e.g., `dev` namespace in Jefferies cluster)
- Option B: One namespace per service per environment (e.g., `dev-marketrisk`)
- Option C: Tenant-prefixed namespaces (e.g., `jefferies-dev`)

**Decision**: Option A - Simple environment names since each tenant has dedicated cluster (isolation already achieved at cluster level).

**Q-12.7: Git Directory Generator Path Patterns**
Should ApplicationSets discover services using:
- Option A: Exact path match (e.g., `argocd/apps/*/envs/dev`)
- Option B: Recursive pattern (e.g., `argocd/apps/**/dev`)
- Option C: Multiple patterns for flexibility

**Decision**: Option A - Exact path match for predictability and performance.

**Q-12.8: Application Sync Policy**
Should generated Applications use:
- Option A: Automated sync with prune and selfHeal enabled
- Option B: Manual sync (require explicit sync button click)
- Option C: Automated sync without prune (safer but leaves orphaned resources)

**Decision**: Option A - Automated sync with prune and selfHeal for true GitOps.

**Q-12.9: Health Assessment**
Should ApplicationSets define custom health checks?
- Option A: Use Argo CD default health checks only
- Option B: Define custom health checks for specific resource types
- Option C: Disable health checks for faster sync

**Decision**: Option A - Default health checks are sufficient for PoC.

**Q-12.10: Retry Logic**
Should ApplicationSets define retry logic for failed syncs?
- Option A: No retry (fail fast)
- Option B: Retry with exponential backoff (e.g., 5s, 10s, 20s)
- Option C: Infinite retry

**Decision**: Option B - Retry with exponential backoff (limit: 3 retries, max duration: 3m).

## 13. Example Scenarios

### 13.1 Scenario: Add New Microservice

**Application Team Action**:
1. Create `CDUsingArgoCD/argocd/apps/payment/base/` with Deployment and Service
2. Create `CDUsingArgoCD/argocd/apps/payment/envs/dev/` with Kustomize overlay
3. Commit to `scalable` branch

**Platform Behavior**:
- ApplicationSet `kynex-dev` automatically discovers `payment` service
- Creates Application `kynex-payment-dev`
- Deploys to `dev` namespace on Kynex cluster

**No platform team involvement required.**

### 13.2 Scenario: Add New Tenant (HSBC)

**Platform Team Action**:
1. Create folder structure: `oneview/nonprod/hsbc/dev/argocd/`
2. Copy Kustomize overlay from `jefferies/dev/argocd/`
3. Customize tenant-specific values (labels, AppProject name)
4. Commit to `scalable` branch

**Platform Behavior**:
- Bootstrap ApplicationSet discovers new `hsbc/dev/argocd/` folder
- Creates ApplicationSet `hsbc-dev` and AppProject `hsbc-dev`
- ApplicationSet discovers services in CDUsingArgoCD
- Deploys services to HSBC cluster

**Time: < 1 hour**

### 13.3 Scenario: Change Platform-Wide Sync Policy

**Platform Team Action**:
1. Edit Kustomize base at `kynex/nonprod/base/applicationset.yaml`
2. Change `syncPolicy.automated.prune: false`
3. Commit to `scalable` branch

**Platform Behavior**:
- All Kynex nonprod environments (dev, sit) inherit the change
- ApplicationSets are updated automatically
- All generated Applications get new sync policy

**No need to edit 10+ individual files.**

### 13.4 Scenario: Promote Change from Nonprod to Prod

**Platform Team Action**:
1. Test change in `kynex/nonprod/` environments
2. Validate in dev and sit
3. Apply same change to `kynex/prod/base/applicationset.yaml`
4. Commit to `scalable` branch

**Platform Behavior**:
- Prod environments (preprod, prod) get the change
- Nonprod and prod remain isolated
- Git history shows clear audit trail

**Follows promotion workflow constraint.**
