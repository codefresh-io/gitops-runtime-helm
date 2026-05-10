# Sojern: Hosted → Hybrid GitOps Runtime migration playbook

Translates Sojern's Hosted runtime (`hgr-sojern-1e325d9`, runtime v0.21, paying tier) into a Hybrid install on gitops-runtime chart `0.29.10` (latest release as of 2026-05-08). Migration is a fresh install on a new cluster, not an in-place upgrade — this avoids the 4 breaking changes between 0.21 and 0.29.

## Prerequisites

The customer must provide:

| Item | Notes |
|---|---|
| New Kubernetes cluster | Empty namespace `cf-runtime` (or whatever you choose); must reach `tunnels.cf-cd.com` outbound |
| Codefresh user token | Created in Codefresh UI → User Settings; loaded into a secret `codefresh-user-token` (key `token`) before install |
| Runtime name | Confirm `sojern-hybrid-prod` is acceptable, or pick another. Must be unique per Codefresh account. |
| Git credentials *(optional)* | Can be set via Codefresh UI post-install, or layered in via `global.runtime.gitCredentials.password.secretKeyRef` |

## Install

```bash
# 1. Create namespace + user-token secret on the target cluster
kubectl create namespace cf-runtime
kubectl -n cf-runtime create secret generic codefresh-user-token \
  --from-literal=token="<sojern-user-token>"

# 2. Install the runtime
helm upgrade --install sojern \
  oci://quay.io/codefresh/gitops-runtime \
  --version 0.29.10 \
  -n cf-runtime \
  -f values.yaml \
  --atomic \
  --history-max 5
```

## What this values.yaml changes vs. their old Hosted values

Fully documented in the file's header comment. Summary:

**Dropped (no longer applicable):**
- `app-proxy.image` (was a CR-37307 dev build)
- `argo-cd.server.env CODEFRESH_PRIORITY_QUEUE=true` (Codefresh-fork only; bundled Argo CD is OSS now)
- `gitops-operator.argoCdNotifications.*` (path removed from chart — operator-side notifications subsystem deleted; not the same as upstream `argo-cd.notifications.*`)
- `argo-cd.eventReporter.*` (replaced by top-level `event-reporters.{cluster,runtime}-event-reporter`)
- `gitops-operator.resources` (chart defaults are fine)

**Added (Hybrid-only required block):**
- `global.codefresh.{url,accountId,userToken}`
- `global.runtime.name`
- `global.integrations.argo-cd.server.auth`
- Top-level `redis-ha.enabled: true` (required by app-proxy when replicaCount > 1)
- HA topology to match Hosted paying-tier (replicas + PDBs across all components)

**Kept:**
- `global.runtime.isConfigurationRuntime: true` (this Hybrid takes over as account's configuration runtime)
- All Sojern-specific Argo CD knobs: resource sizing, `gerritssh.p.sojern.net` knownHost, `controller.self.heal.timeout.seconds=60`, repo-server `ARGOCD_EXEC_TIMEOUT=3m`, status/operation processors

## Pre-install verification

```bash
# Render and inspect — should produce ~201 manifests with no template errors
helm template sojern oci://quay.io/codefresh/gitops-runtime \
  --version 0.29.10 -n cf-runtime -f values.yaml > /tmp/render.yaml

# Spot-check key resources are configured for HA
grep -c "kind: PodDisruptionBudget" /tmp/render.yaml   # expect 11
grep -c "kind: StatefulSet" /tmp/render.yaml            # expect 3 (controller + 2× redis-ha)
```

## Post-install verification (smoke tests)

```bash
NS=cf-runtime
RUNTIME=sojern-hybrid-prod

# 1. All HA workloads have ≥2 replicas ready
kubectl -n $NS get deploy -l 'app.kubernetes.io/part-of in (app-proxy,argocd,internal-router)' \
  -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas

# 2. Both redis-ha clusters healthy (gitops-runtime-level + argo-cd-level)
kubectl -n $NS get statefulset | grep redis-ha    # expect 2 STSs, 3/3 each

# 3. Tunnel is registered (look for runtime online in Codefresh UI)
kubectl -n $NS logs -l app=codefresh-tunnel-client --tail=50 | grep -i "registered\|connected"

# 4. Runtime appears in Codefresh and is marked the configuration runtime
# Visit: https://g.codefresh.io/2.0/account-settings/runtime
# Check: $RUNTIME shows online, "isConfigurationRuntime" badge present
```

## Functional validation (the test that matters)

Per the engineering decision in the May 6 thread, "the install renders and pods start" is *not* sufficient sign-off. Before declaring the playbook ready:

- [ ] Connect a non-prod copy of one of Sojern's GitOps source repos
- [ ] Trigger an app sync; confirm event-reporter publishes events to Codefresh
- [ ] Trigger a workflow; confirm commit-status reports back to Gerrit
- [ ] Verify image enrichment runs end-to-end on a test image
- [ ] Diff observed event throughput against current Hosted baseline

These exercise the breaking changes that made us choose fresh-install over upgrade in the first place (Argo Events / event-reporter rewrites, Gerrit knownHost handling).

## Known caveats

1. **Comment header in `values.yaml` documents what was dropped vs. Hosted** — keep it in sync if values change.
2. **Top-level `redis-ha.enabled: true` is mandatory** for HA app-proxy. The chart's stock `values-ha.yaml` does *not* set this even though it sets `app-proxy.replicaCount: 2`, so layering `-f values-ha.yaml` alone would fail validation. Filed separately as a chart fix.
3. **Image enrichment images** are pinned to `1.1.27-main` in chart defaults — confirm Sojern's enrichment templates don't reference older tags.
4. **`controller.self.heal.timeout.seconds: "60"`** is a Sojern-specific carryover from their Gerrit-driven dev flow. Revisit once their flow stabilises post-migration.

## Files

- `values.yaml` — production values, ready to install with
- `README.md` — this file
