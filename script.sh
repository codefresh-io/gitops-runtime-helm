echo "Checking Argo CD service labels..."
S=$(kubectl get svc -A -l app.kubernetes.io/component=server,app.kubernetes.io/part-of=argocd -o name 2>/dev/null)
R=$(kubectl get svc -A -l app.kubernetes.io/component=repo-server,app.kubernetes.io/part-of=argocd -o name 2>/dev/null)
D=$(kubectl get svc -A -l app.kubernetes.io/component=redis,app.kubernetes.io/part-of=argocd -o name 2>/dev/null)
[ -z "$S" ] && echo "❌ Server: NOT FOUND" || echo "✅ Server: Found"
[ -z "$R" ] && echo "❌ Repo: NOT FOUND" || echo "✅ Repo: Found"
[ -z "$D" ] && echo "❌ Redis: NOT FOUND" || echo "✅ Redis: Found"
if [ -n "$S" ] && [ -n "$R" ] && [ -n "$D" ]; then
  echo "✅ SUCCESS: All Argo CD services have proper labels for auto-detection."
else
  echo "❌ ISSUE: Missing services. Required labels:"
  echo "- Server: app.kubernetes.io/component=server,app.kubernetes.io/part-of=argocd"
  echo "- Repo: app.kubernetes.io/component=repo-server,app.kubernetes.io/part-of=argocd"
  echo "- Redis: app.kubernetes.io/component=redis,app.kubernetes.io/part-of=argocd"
fi
