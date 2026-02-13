#!/bin/bash
export AWS_DEFAULT_PROFILE=test

echo "=== Argo CD Cleanup Script ==="
echo ""

echo "Step 1: Removing finalizers from all applications..."
for app in $(kubectl get applications.argoproj.io -n argocd -o name 2>/dev/null); do
  echo "  Patching $app"
  kubectl patch $app -n argocd --type json -p '[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
done

echo ""
echo "Step 2: Deleting all applications..."
kubectl delete applications.argoproj.io -n argocd --all --force --grace-period=0 2>/dev/null || echo "  No applications to delete"

echo ""
echo "Step 3: Removing finalizers from all applicationsets..."
for appset in $(kubectl get applicationsets.argoproj.io -n argocd -o name 2>/dev/null); do
  echo "  Patching $appset"
  kubectl patch $appset -n argocd --type json -p '[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
done

echo ""
echo "Step 4: Deleting all applicationsets..."
kubectl delete applicationsets.argoproj.io -n argocd --all --force --grace-period=0 2>/dev/null || echo "  No applicationsets to delete"

echo ""
echo "Step 5: Deleting all appprojects (except default)..."
for proj in $(kubectl get appprojects.argoproj.io -n argocd -o name 2>/dev/null | grep -v "default"); do
  echo "  Deleting $proj"
  kubectl delete $proj -n argocd --force --grace-period=0 2>/dev/null || true
done

echo ""
echo "=== Cleanup complete! ==="
echo ""
echo "Verification:"
argocd app list 2>/dev/null || echo "No applications found"
argocd appset list 2>/dev/null || echo "No applicationsets found"
