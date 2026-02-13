#!/bin/bash

# ArgoCD Cluster and Repository Registration Script
# This script registers spoke clusters and repositories with ArgoCD

set -e

echo "=========================================="
echo "ArgoCD Cluster & Repository Registration"
echo "=========================================="

# Get ArgoCD admin password
echo ""
echo "📝 Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
echo "Admin Password: $ARGOCD_PASSWORD"

# Login to ArgoCD CLI
echo ""
echo "🔐 Logging into ArgoCD CLI..."
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure

# Register Spoke Clusters
echo ""
echo "🔗 Registering Spoke Clusters..."

# Get current kubectl contexts
echo "  - Detecting kubectl contexts..."
SPOKE1_CONTEXT=$(kubectl config get-contexts -o name | grep spoke1 | grep -v arn || echo "")
SPOKE2_CONTEXT=$(kubectl config get-contexts -o name | grep spoke2 | grep -v arn || echo "")

if [ -z "$SPOKE1_CONTEXT" ]; then
  echo "  ⚠️  Warning: spoke1 context not found, skipping..."
else
  echo "  - Registering spoke1 (context: $SPOKE1_CONTEXT)..."
  argocd cluster add "$SPOKE1_CONTEXT" --name spoke1.us-east-1.eksctl.io --upsert
fi

if [ -z "$SPOKE2_CONTEXT" ]; then
  echo "  ⚠️  Warning: spoke2 context not found, skipping..."
else
  echo "  - Registering spoke2 (context: $SPOKE2_CONTEXT)..."
  argocd cluster add "$SPOKE2_CONTEXT" --name spoke-cpe-dev-usw2 --upsert
fi

# Add Repositories
echo ""
echo "📦 Adding Git Repositories..."
echo "  - Adding CDUsingArgoCD repository..."
argocd repo add https://github.com/CodeByMurali/CDUsingArgoCD.git

echo "  - Adding gitops-demo repository..."
argocd repo add https://github.com/CodeByMurali/gitops-demo.git

# Verify Registration
echo ""
echo "✅ Verification:"
echo ""
echo "Registered Clusters:"
argocd cluster list

echo ""
echo "Registered Repositories:"
argocd repo list

echo ""
echo "=========================================="
echo "✅ Registration Complete!"
echo "=========================================="
