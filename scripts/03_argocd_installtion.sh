#!/bin/bash

# INSTALL ARGOCD ON HUB CLUSTER
# This script installs ArgoCD on your Kubernetes cluster, NOT the ArgoCD CLI
# 
# To install ArgoCD CLI:
# - Mac/Linux/WSL: brew install argocd
# - Windows: Download from https://github.com/argoproj/argo-cd/releases/latest
# - WSL: You can also use brew in WSL

echo "=========================================="
echo "ArgoCD Installation Script"
echo "=========================================="
echo ""
echo "WARNING: Ensure you've switched context to the hub cluster before running this script"
echo "Use: kubectl config use-context <cluster-context-name>"
echo ""
echo "Current context:"
kubectl config current-context
echo ""

# Auto-confirm if running non-interactively or if AUTO_CONFIRM is set
if [[ -n "$AUTO_CONFIRM" ]] || [[ ! -t 0 ]]; then
    confirm="yes"
else
    read -p "Is this the correct hub cluster context? (yes/no): " confirm
fi

if [[ "$confirm" != "yes" ]]; then
    echo ""
    echo "Please switch context first using:"
    echo "  kubectl config get-contexts  # List all contexts"
    echo "  kubectl config use-context <hub-cluster-context>"
    echo ""
    exit 0
fi

echo ""
echo "Cleaning up any existing ArgoCD installation..."

# Remove finalizers from stuck applications first
echo "Removing finalizers from stuck applications..."
for app in $(kubectl get applications -n argocd -o name 2>/dev/null); do
  kubectl patch $app -n argocd -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done

# Delete namespace if it exists (with timeout)
echo "Deleting argocd namespace..."
kubectl delete namespace argocd --timeout=30s 2>/dev/null || true

# If namespace still exists, force finalize it
if kubectl get namespace argocd 2>/dev/null; then
  echo "Force finalizing namespace..."
  kubectl get namespace argocd -o json | jq '.spec.finalizers = []' | kubectl replace --raw /api/v1/namespaces/argocd/finalize -f - 2>/dev/null || true
fi

# Wait a bit for namespace to be fully deleted
sleep 5

# Force delete any existing CRDs that might have annotation issues
echo "Cleaning up CRDs..."
kubectl delete crd applicationsets.argoproj.io --timeout=10s 2>/dev/null || true
kubectl delete crd applications.argoproj.io --timeout=10s 2>/dev/null || true
kubectl delete crd appprojects.argoproj.io --timeout=10s 2>/dev/null || true

# If CRDs still exist, remove their finalizers
for crd in applicationsets.argoproj.io applications.argoproj.io appprojects.argoproj.io; do
  if kubectl get crd $crd 2>/dev/null; then
    echo "Force removing finalizers from $crd..."
    kubectl patch crd $crd -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  fi
done

# Wait for cleanup
sleep 3

echo "Creating argocd namespace..."
kubectl create namespace argocd

echo ""
echo "Installing ArgoCD (stable version with server-side apply)..."
# Use server-side apply to handle large CRD annotations
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "Waiting for ArgoCD to be ready (this may take a few minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo ""
echo "Verifying ArgoCD CRDs are installed..."
kubectl get crd | grep argoproj

echo ""
echo "=========================================="
echo "ArgoCD installed successfully!"
echo "=========================================="
echo ""
echo "To access ArgoCD:"
echo ""
echo "1. Get the initial admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
echo ""
echo "2. Port forward to access the UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "3. Access ArgoCD UI at: https://localhost:8080"
echo "   Username: admin"
echo "   Password: (from step 1)"
echo ""
echo "4. (Optional) For WSL users, open browser with:"
echo "   cmd.exe /c start https://localhost:8080"
echo ""
echo "5. Add spoke clusters to ArgoCD:"
echo "   argocd cluster add <spoke-cluster-context>"
echo ""
