#!/bin/bash

# Check if NAMESPACE is set
if [ -z "$NAMESPACE" ]; then
  echo "❌ ERROR: NAMESPACE environment variable is not set."
  echo "Please set the NAMESPACE environment variable and try again."
  echo "Example: NAMESPACE=argocd ./verify-argocd-auto-detection.sh"
  exit 1
fi

echo "Checking Argo CD service labels in namespace '$NAMESPACE'..."
S=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=server,app.kubernetes.io/part-of=argocd -o name 2>/dev/null)
R=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=repo-server,app.kubernetes.io/part-of=argocd -o name 2>/dev/null)
D=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/component=redis,app.kubernetes.io/part-of=argocd -o name 2>/dev/null)
[ -z "$S" ] && echo "❌ Server: NOT FOUND" || echo "✅ Server: Found"
[ -z "$R" ] && echo "❌ Repo: NOT FOUND" || echo "✅ Repo: Found"
[ -z "$D" ] && echo "❌ Redis: NOT FOUND" || echo "✅ Redis: Found"
if [ -n "$S" ] && [ -n "$R" ] && [ -n "$D" ]; then
  echo "✅ SUCCESS: All Argo CD services have proper labels for auto-detection."
else
  echo "❌ ISSUE: Missing services in namespace '$NAMESPACE'. Required labels:"
  echo "- Server: app.kubernetes.io/component=server,app.kubernetes.io/part-of=argocd"
  echo "- Repo: app.kubernetes.io/component=repo-server,app.kubernetes.io/part-of=argocd"
  echo "- Redis: app.kubernetes.io/component=redis,app.kubernetes.io/part-of=argocd"
fi
