# Migrating to Argo Rollouts (User-Based Canary)

This guide is part of this POC only; all paths are relative to this folder.

If your app is on **Argo CD** with a **Recreate** Deployment, you can move to a **Rollout** (canary strategy) that Argo CD syncs from Git. A single **Rollout** resource then manages stable and canary ReplicaSets; NGINX Ingress still routes by `X-User-Id`.

## Why Argo Rollouts (with Argo CD)

- **Single resource**: One Rollout replaces separate stable + canary Deployments.
- **Controller-managed Services**: Argo updates `stable-svc` and `canary-svc` selectors so they always point to the correct ReplicaSets.
- **Promote / Abort**: `kubectl argo rollouts promote` or `rollouts abort` with a single command.
- **Optional analysis**: Automate promotion/rollback with Prometheus (or other providers).

## Prerequisites

- **Argo Rollouts controller** installed in the cluster ([install](https://argoproj.github.io/argo-rollouts/installation/)).
- **NGINX Ingress Controller** (unchanged; still used for header-based canary routing).
- **Argo CD** (you already use it); it will sync the Rollout from this repo.
- `kubectl` and the [Argo Rollouts kubectl plugin](https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin) for promote/abort.

## Two Migration Paths

### Path A: You use Argo CD with a Recreate Deployment (or plain Deployments)

1. **Back up** existing resources:
   ```bash
   kubectl get deployment app-stable app-canary -n canary-demo -o yaml > backup-deployments.yaml
   kubectl get svc stable-svc canary-svc -n canary-demo -o yaml >> backup-deployments.yaml
   ```

2. **Apply** the Argo Rollout and Services **first** (so new pods start before removing old ones; no downtime):
   ```bash
   kubectl apply -f k8s/base/namespace.yaml
   kubectl apply -f k8s/argo-rollout/services.yaml
   kubectl apply -f k8s/argo-rollout/rollout.yaml
   kubectl apply -f k8s/base/ingress-stable.yaml
   kubectl apply -f k8s/base/ingress-canary.yaml
   ```
   Or with Kustomize:
   ```bash
   kubectl apply -k k8s/argo-rollout
   ```

3. **Wait** for the Rollout to be healthy, then **remove** the old Deployments (if they still exist) to avoid duplicate pods:
   ```bash
   kubectl argo rollouts status canary-demo -n canary-demo
   kubectl delete deployment app-stable app-canary -n canary-demo --ignore-not-found
   ```

4. **Verify**:
   ```bash
   kubectl argo rollouts status canary-demo -n canary-demo
   kubectl get pods -n canary-demo -l app=canary-demo
   ```
   Traffic behavior is unchanged: no header → stable-svc; `X-User-Id` in canary list → canary-svc.

### Path B: You already have a Rollout (different app or name) in this cluster

1. **Identify** your current Rollout:
   ```bash
   kubectl get rollout -n <namespace>
   kubectl get rollout <name> -n <namespace> -o yaml > current-rollout.yaml
   ```

2. **Add** canary and stable Services if not present:
   - Ensure the Rollout spec has `strategy.canary.stableService` and `strategy.canary.canaryService` set.
   - Create the two Services (see `k8s/argo-rollout/services.yaml`) so the controller can update their selectors.

3. **Add** NGINX canary Ingress (same host/path as main, with `canary-by-header` / `canary-by-header-pattern` pointing to `canary-svc`). Main Ingress should point to `stable-svc`.

4. **Trigger** a canary by updating the Rollout template (e.g. image or env):
   ```bash
   kubectl argo rollouts set image canary-demo app=canary-demo:2 -n canary-demo
   ```
   The controller will create a canary ReplicaSet and pause at the first pause step. Users with the canary header will hit canary-svc.

5. **Promote** when ready:
   ```bash
   kubectl argo rollouts promote canary-demo -n canary-demo
   ```

## Directory Layout (Argo variant)

Use the **`k8s/argo-rollout/`** folder instead of deploying `k8s/base/` stable + canary Deployments:

```
k8s/
├── base/
│   ├── namespace.yaml
│   ├── stable.yaml          # Ignored when using Argo
│   ├── canary.yaml          # Ignored when using Argo
│   ├── ingress-stable.yaml  # Shared
│   └── ingress-canary.yaml  # Shared
└── argo-rollout/
    ├── kustomization.yaml   # Namespace + services + rollout + ingresses
    ├── rollout.yaml        # Single Rollout (canary strategy)
    ├── services.yaml       # stable-svc, canary-svc (Argo updates selectors)
    └── analysis-template.yaml  # Optional
```

## Rollout lifecycle (user-based canary)

1. **Initial deploy**: Rollout has one ReplicaSet (stable). Both Services point to it until an update.
2. **New version**: Update image (or template):
   ```bash
   kubectl argo rollouts set image canary-demo app=<your-registry>/canary-demo:2 -n canary-demo
   ```
   Argo creates a canary ReplicaSet, updates `canary-svc` to target it, and pauses at the first `pause: {}` step.
3. **Test**: Requests with `X-User-Id: user-canary-001` (or your pattern) go to canary-svc → canary pods.
4. **Promote**: When satisfied, run:
   ```bash
   kubectl argo rollouts promote canary-demo -n canary-demo
   ```
   Rollout completes; canary becomes the new stable.
5. **Abort** (rollback): If something is wrong:
   ```bash
   kubectl argo rollouts abort canary-demo -n canary-demo
   ```
   Traffic goes back to stable; canary ReplicaSet is scaled down after the abort delay.

## Optional: Analysis (auto promote/abort)

To add metric-based promotion or abort, use an AnalysisTemplate and reference it in the Rollout:

```yaml
# In rollout.yaml under strategy.canary
strategy:
  canary:
    stableService: stable-svc
    canaryService: canary-svc
    steps:
    - setWeight: 50
    - pause: { duration: 2m }
    - analysis:
        templates:
        - templateName: success-rate
    - setWeight: 100
```

Apply the AnalysisTemplate and ensure Prometheus (or your provider) is available. Then the rollout will automatically promote or abort based on the analysis result.

## Summary

| Before (Deployments) | After (Argo Rollouts) |
|----------------------|------------------------|
| Two Deployments (stable, canary) | One Rollout (stable + canary ReplicaSets) |
| Manual image updates on both | Single `set image`; controller manages canary |
| Manual scale/cleanup | Promote / Abort with one command |
| Same NGINX header routing | Same NGINX header routing (no change) |

User-based routing (X-User-Id → canary) is unchanged; only the way stable/canary pods are created and how you promote is managed by Argo Rollouts.
