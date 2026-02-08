# Runbook: Deploy, Test, Promote

## Bringing an existing deployment under canary (no downtime)

If you already have a running app on AKS with **Argo CD** and **Recreate strategy**:

> **📘 See [Migration Guide: Recreate → Canary](./03-Migrate-From-Recreate.md)** for steps to convert to canary (all within this POC).

Quick steps:

1. **Convert your current Deployment** to "stable":
   - Add labels: `version: stable`
   - Remove `strategy.type: Recreate` (if present) - canary doesn't need it
   - Create/update Service to select stable pods (`stable-svc`)
2. **Add a second Deployment** for the new version (`app-canary`) with `version: canary` and Service `canary-svc`.
3. **Update your existing Ingress** to point to `stable-svc` (or duplicate its host/path as `ingress-stable.yaml`).
4. **Add the canary Ingress** (same host/path, `canary: true`, `canary-by-header`, `canary-by-header-pattern`) pointing to `canary-svc`.

**Key point**: No need to delete the existing Deployment; canary is **additive**. Your existing app keeps running (no downtime).

---

## Prerequisites

- AKS cluster with **kubectl** context set
- **NGINX Ingress Controller** installed (e.g. [AKS Application Routing](https://learn.microsoft.com/en-us/azure/aks/app-routing-nginx) or [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/))
- Container images for stable (`canary-demo:1`) and canary (`canary-demo:2`) built and pushed to your registry (e.g. ACR)
- **Argo CD (optional):** Point your Application at this POC path in Git; Argo CD will sync `k8s/base/` or `k8s/argo-rollout/` instead of your current Recreate Deployment.

## 1. Build and push sample images (POC)

From the POC root (folder that contains `sample-app`, `k8s`, `docs`):

```bash
cd sample-app
docker build --build-arg APP_VERSION=1 -t <ACR_NAME>.azurecr.io/canary-demo:1 .
docker build --build-arg APP_VERSION=2 -t <ACR_NAME>.azurecr.io/canary-demo:2 .
az acr login --name <ACR_NAME>
docker push <ACR_NAME>.azurecr.io/canary-demo:1
docker push <ACR_NAME>.azurecr.io/canary-demo:2
```

Update `k8s/base/stable.yaml` and `k8s/base/canary.yaml` to use `<ACR_NAME>.azurecr.io/canary-demo:1` and `:2` (and set `imagePullPolicy` / imagePullSecrets if private).

## 2. Deploy (no downtime)

### Option A: Plain Deployments (stable + canary)

Deploy in order: namespace → stable (existing) → canary → ingresses. Existing traffic stays on stable.

```bash
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/stable.yaml
kubectl apply -f k8s/base/canary.yaml
kubectl apply -f k8s/config/canary-users.yaml
kubectl apply -f k8s/base/ingress-stable.yaml
kubectl apply -f k8s/base/ingress-canary.yaml
```

Or use the script:

```powershell
.\scripts\deploy.ps1 -Namespace canary-demo
```

### Option B: Argo Rollouts (works with Argo CD)

Single Rollout resource; controller manages stable/canary Services. See [Migrate to Argo Rollouts](./04-Migrate-To-Argo-Rollouts.md) (same POC).

```bash
kubectl apply -k k8s/argo-rollout
```

Or: `.\scripts\deploy.ps1 -Namespace canary-demo -UseArgoRollout`

Wait for pods:

```bash
kubectl get pods -n canary-demo -w
```

## 3. Get Ingress address

```bash
kubectl get ingress -n canary-demo
# Use ADDRESS or the LB IP from the NGINX ingress controller
```

If using a LoadBalancer for the ingress controller:

```bash
kubectl get svc -n ingress-nginx
# Use EXTERNAL-IP
```

## 4. Test

- **Stable (most users)** – no header or unknown user ID:
  ```bash
  curl -s http://<INGRESS_IP>/
  # Expect: Version: 1 (stable)
  ```

- **Canary (allowed user IDs)** – header `X-User-Id` in the pattern list:
  ```bash
  curl -s -H "X-User-Id: user-canary-001" http://<INGRESS_IP>/
  # Expect: Version: 2 (canary)
  curl -s -H "X-User-Id: user-canary-002" http://<INGRESS_IP>/
  # Expect: Version: 2 (canary)
  ```

Use the test script (set `$INGRESS_IP` first):

```powershell
.\scripts\test-canary.ps1 -IngressHost "http://<INGRESS_IP>"
```

## 5. Add more canary users

Edit `k8s/base/ingress-canary.yaml`: update the regex in `canary-by-header-pattern`, e.g.:

```yaml
nginx.ingress.kubernetes.io/canary-by-header-pattern: "user-canary-001|user-canary-002|beta-.*"
```

Then:

```bash
kubectl apply -f k8s/base/ingress-canary.yaml
```

## 6. Promote canary to stable (full rollout)

### If using plain Deployments

1. Update **stable** Deployment to use the canary image (and same config as canary):
   ```bash
   kubectl set image deployment/app-stable app=<ACR>.azurecr.io/canary-demo:2 -n canary-demo
   ```
2. Optionally scale down canary and remove canary ingress so only one path remains:
   ```bash
   kubectl scale deployment/app-canary --replicas=0 -n canary-demo
   kubectl delete ingress app-canary-ingress -n canary-demo
   ```
3. For the **next** release: build new canary image (e.g. `:3`), deploy new canary Deployment + Service + canary Ingress again; stable stays on current prod.

See `scripts/promote-canary.ps1` for an example.

### If using Argo Rollouts

When the new version is validated, promote the rollout (moves to next step and eventually completes):

```bash
kubectl argo rollouts promote canary-demo -n canary-demo
```

To roll out a new version later: update the Rollout template (e.g. image) and the controller will create a new canary and pause again:

```bash
kubectl argo rollouts set image canary-demo app=<ACR>.azurecr.io/canary-demo:2 -n canary-demo
```

## 7. Rollback canary

To stop sending canary users to the new version:

**If using plain Deployments:**
- **Option A**: Delete the canary Ingress so all traffic (including previous canary users) goes to stable:
  ```bash
  kubectl delete ingress app-canary-ingress -n canary-demo
  ```
- **Option B**: Scale canary to 0 and delete canary Ingress (same effect).

**If using Argo Rollouts:** Abort the rollout (traffic returns to stable; canary ReplicaSet scales down):
```bash
kubectl argo rollouts abort canary-demo -n canary-demo
```

No need to change stable Deployment; no downtime.
