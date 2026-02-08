# End-to-End Setup Guide — User-Based Canary on AKS

Use this single guide to run the full POC from scratch: prerequisites → deploy → test stable → trigger canary → test canary users → promote (or rollback). All paths are relative to this POC folder.

---

## What You’ll Demonstrate

| Step | What happens |
|------|----------------|
| 1 | AKS + NGINX Ingress (+ optional Argo Rollouts) ready |
| 2 | Sample app v1 (stable) and v2 (canary) images built and pushed |
| 3 | Canary stack deployed (stable + canary routing by `X-User-Id`) |
| 4 | **Stable:** Requests without header → Version 1 |
| 5 | **Canary:** Requests with `X-User-Id: user-canary-001` → Version 2 |
| 6 | Promote canary to full rollout or abort (rollback) |

---

## Prerequisites Checklist

- [ ] **Azure CLI** logged in (`az login`)
- [ ] **kubectl** installed and context set to your AKS cluster
- [ ] **Docker** (or Podman) for building images
- [ ] **NGINX Ingress Controller** on the cluster (see [Step 1.2](#12-nginx-ingress-controller))
- [ ] **Optional – Argo Rollouts path:** Argo Rollouts controller + kubectl plugin (see [Step 1.3](#13-optional-argo-rollouts-controller))
- [ ] **Optional – Argo CD:** Argo CD installed; you’ll point an Application at this repo path

---

## Step 1 — Cluster and Controllers

### 1.1 AKS and kubectl

```bash
# Login and set subscription
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# Get AKS credentials
az aks get-credentials --resource-group <RG_NAME> --name <AKS_CLUSTER> --overwrite-existing

# Verify
kubectl get nodes
```

### 1.2 NGINX Ingress Controller

If you don’t have NGINX Ingress yet:

```bash
# Add Helm repo and install (example: ingress-nginx)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx

# Wait for EXTERNAL-IP
kubectl get svc -n ingress-nginx -w
```

Or use [AKS Application Routing (NGINX)](https://learn.microsoft.com/en-us/azure/aks/app-routing-nginx). Record the **ingress controller’s external IP or hostname**; you’ll use it as `<INGRESS_IP>` when testing.

### 1.3 (Optional) Argo Rollouts controller

Only if you want **Track B** (Argo Rollouts):

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Kubectl plugin (optional, for promote/abort)
# Windows (PowerShell): install from https://github.com/argoproj/argo-rollouts/releases
# Linux/Mac:
#   curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
#   chmod +x kubectl-argo-rollouts-linux-amd64 && sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

---

## Step 2 — Build and Push Sample Images

From the **POC root** (folder containing `sample-app`, `k8s`, `docs`):

```bash
# Replace <ACR_NAME> with your Azure Container Registry name
export ACR_NAME=myregistry

cd sample-app
docker build --build-arg APP_VERSION=1 -t $ACR_NAME.azurecr.io/canary-demo:1 .
docker build --build-arg APP_VERSION=2 -t $ACR_NAME.azurecr.io/canary-demo:2 .

az acr login --name $ACR_NAME
docker push $ACR_NAME.azurecr.io/canary-demo:1
docker push $ACR_NAME.azurecr.io/canary-demo:2
cd ..
```

**If using a private ACR:** Update image names in the manifests and add `imagePullSecrets` if required.

- **Track A (Deployments):** Edit `k8s/base/stable.yaml` and `k8s/base/canary.yaml`: set `image` to `$ACR_NAME.azurecr.io/canary-demo:1` and `:2`.
- **Track B (Argo Rollouts):** Edit `k8s/argo-rollout/rollout.yaml`: set `spec.template.spec.containers[0].image` to `$ACR_NAME.azurecr.io/canary-demo:1`.

---

## Step 3 — Deploy the Canary Stack

Choose **Track A** (two Deployments) or **Track B** (Argo Rollouts). Use one only.

### Track A — Two Deployments (stable + canary)

```bash
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/stable.yaml
kubectl apply -f k8s/base/canary.yaml
kubectl apply -f k8s/config/canary-users.yaml
kubectl apply -f k8s/base/ingress-stable.yaml
kubectl apply -f k8s/base/ingress-canary.yaml
```

Or from the POC root with the script:

```powershell
.\scripts\deploy.ps1 -Namespace canary-demo
```

### Track B — Argo Rollouts (single Rollout)

```bash
kubectl apply -k k8s/argo-rollout
```

Or:

```powershell
.\scripts\deploy.ps1 -Namespace canary-demo -UseArgoRollout
```

### Wait for pods

```bash
kubectl get pods -n canary-demo -w
```

Leave when all pods are `Running` and ready. For Track B you should see one ReplicaSet (stable); canary appears after you update the image.

---

## Step 4 — Get the App URL

Ingress may get its address from the NGINX controller. Get the host or IP you’ll use in the browser or `curl`:

```bash
# Ingress in canary-demo (if ADDRESS is set)
kubectl get ingress -n canary-demo

# Or use the NGINX Ingress controller’s external IP
kubectl get svc -n ingress-nginx
```

Use the **EXTERNAL-IP** (or ADDRESS from ingress) as `<INGRESS_IP>`. If you need a hostname, add a DNS record or use `curl -H "Host: canary-demo.example.com"` as in your ingress.

Example:

```bash
export INGRESS_IP=<paste EXTERNAL-IP or hostname here>
```

---

## Step 5 — Test Stable (Most Users)

Requests **without** the canary header go to the stable version.

```bash
curl -s http://$INGRESS_IP/
```

**Expected:** HTML showing **Version: 1 (stable)** and `X-User-Id: (not set)`.

Repeat a few times; you should always get v1.

---

## Step 6 — Test Canary (Selected User IDs)

Only requests with `X-User-Id` matching the canary pattern (e.g. `user-canary-001`, `user-canary-002`) go to the new version.

**Track A:** Canary is already running (v2). Send the header:

```bash
curl -s -H "X-User-Id: user-canary-001" http://$INGRESS_IP/
```

**Expected:** **Version: 2 (canary)**.

**Track B:** First trigger a canary by updating the Rollout image to v2:

```bash
# Replace <ACR_NAME> with your registry
kubectl argo rollouts set image canary-demo app=<ACR_NAME>.azurecr.io/canary-demo:2 -n canary-demo
```

Wait for the canary ReplicaSet to be up (rollout will pause at the canary step):

```bash
kubectl argo rollouts status canary-demo -n canary-demo
kubectl get pods -n canary-demo
```

Then send the canary header:

```bash
curl -s -H "X-User-Id: user-canary-001" http://$INGRESS_IP/
```

**Expected:** **Version: 2 (canary)**.

**Verify a non-canary user still gets stable:**

```bash
curl -s -H "X-User-Id: random-user-999" http://$INGRESS_IP/
```

**Expected:** **Version: 1 (stable)**.

You’ve now shown end-to-end: stable traffic, canary-only traffic by user ID, and no downtime.

---

## Step 7 — Promote or Rollback

### Promote (make canary the new stable)

**Track A (Deployments):**

```bash
# Point stable deployment to the canary image
kubectl set image deployment/app-stable app=<ACR_NAME>.azurecr.io/canary-demo:2 -n canary-demo
kubectl rollout status deployment/app-stable -n canary-demo
```

Optionally remove canary and its ingress:

```bash
kubectl scale deployment/app-canary --replicas=0 -n canary-demo
kubectl delete ingress app-canary-ingress -n canary-demo
```

**Track B (Argo Rollouts):**

```bash
kubectl argo rollouts promote canary-demo -n canary-demo
```

After promotion, **all** users get the new version (no header needed). For the next release, deploy a new canary (Track A: update canary deployment image; Track B: `set image` again and promote when ready).

### Rollback (send canary users back to stable)

**Track A:** Remove canary ingress so everyone goes to stable:

```bash
kubectl delete ingress app-canary-ingress -n canary-demo
```

**Track B:**

```bash
kubectl argo rollouts abort canary-demo -n canary-demo
```

Traffic returns to stable; canary ReplicaSet is scaled down.

---

## Step 8 — (Optional) Argo CD

To drive this from Git with Argo CD:

1. Push this POC (or the relevant manifests) to a Git repo.
2. In Argo CD, create an **Application** that points to that repo and path:
   - **Track A:** Path to `k8s/base/` (and optionally `k8s/config/`); include namespace, stable, canary, and both ingresses.
   - **Track B:** Path to `k8s/argo-rollout/` (Kustomize) so Argo CD syncs the Rollout, Services, and ingresses.
3. Sync. Argo CD will apply the manifests; you still trigger canary (image update) and promote/abort as in Step 6 and Step 7.

Your current app (Argo CD + Recreate) is replaced by this canary setup in the same Git repo; no Recreate, no downtime.

---

## Quick Reference — Commands

| Action | Track A (Deployments) | Track B (Argo Rollouts) |
|--------|------------------------|--------------------------|
| Deploy | `kubectl apply -f k8s/base/namespace.yaml` then stable, canary, config, ingresses | `kubectl apply -k k8s/argo-rollout` |
| Test stable | `curl -s http://$INGRESS_IP/` | Same |
| Test canary | `curl -s -H "X-User-Id: user-canary-001" http://$INGRESS_IP/` | Same (after `set image`) |
| Trigger canary | Deploy/update canary deployment with v2 image | `kubectl argo rollouts set image canary-demo app=<IMAGE>:2 -n canary-demo` |
| Promote | `kubectl set image deployment/app-stable app=<IMAGE>:2 -n canary-demo` | `kubectl argo rollouts promote canary-demo -n canary-demo` |
| Rollback | `kubectl delete ingress app-canary-ingress -n canary-demo` | `kubectl argo rollouts abort canary-demo -n canary-demo` |

---

## Troubleshooting

| Issue | Check |
|-------|--------|
| 502 / connection refused | Pods ready? `kubectl get pods -n canary-demo`. Ingress backend service names match (stable-svc, canary-svc). |
| Everyone gets same version | Canary ingress present? `kubectl get ingress -n canary-demo`. NGINX canary annotations: `canary: "true"`, `canary-by-header: "X-User-Id"`, `canary-by-header-pattern` (or value). |
| Canary users get stable (Track B) | Rollout in canary step? `kubectl argo rollouts status canary-demo -n canary-demo`. Canary ReplicaSet running? `kubectl get rs -n canary-demo`. |
| ImagePullBackOff | Image name and registry in manifests; ACR login and imagePullSecrets if private. |

For more detail, see [Architecture](01-Architecture.md) and [Runbook](02-Runbook.md).
