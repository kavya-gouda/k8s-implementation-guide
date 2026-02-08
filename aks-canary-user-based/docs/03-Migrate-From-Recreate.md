# Migrating from Recreate Strategy to Canary Deployment

This POC is self-contained; all paths and manifests refer only to this folder.

## Current State: Argo CD + Recreate Strategy

Your application is deployed with **Argo CD** (GitOps) and uses a Deployment with `strategy.type: Recreate`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  strategy:
    type: Recreate  # ❌ Causes downtime
  replicas: 2
  template:
    # ... your app config
```

**Problems with Recreate:**
- Old pods are **terminated first** → service interruption
- New pods are created **after** old ones are gone → downtime window
- All users experience the new version at once → no gradual rollout

## Target State: Canary Deployment (User-Based)

With canary deployment:
- ✅ **No downtime** - stable pods stay running while canary is deployed
- ✅ **Gradual rollout** - only specific users (by user ID) see the new version
- ✅ **Safe testing** - validate new version with real users before full rollout
- ✅ **Easy rollback** - remove canary ingress to revert instantly

After migration, Argo CD continues to sync from Git; you replace the Recreate Deployment with the canary setup (stable + canary or a Rollout) in the same repo path Argo CD watches.

## Migration Steps (Zero Downtime)

### Step 1: Identify Your Current Deployment

```bash
kubectl get deployment -n <your-namespace>
kubectl get deployment <your-deployment-name> -n <your-namespace> -o yaml > current-deployment.yaml
```

### Step 2: Convert to Stable Deployment

Take your existing Deployment and:

1. **Rename** it to `app-stable` (or keep the name and add labels)
2. **Add labels** for canary routing:
   ```yaml
   labels:
     app: <your-app-name>
     version: stable
   ```
3. **Remove or change** `strategy.type: Recreate` → use default `RollingUpdate` (or leave it; canary doesn't depend on this)
4. **Ensure** it has a Service that selects these pods

**Example conversion:**

```yaml
# Before (recreate strategy)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-frontend-app
spec:
  strategy:
    type: Recreate  # Remove this
  replicas: 2
  selector:
    matchLabels:
      app: my-frontend-app
  template:
    metadata:
      labels:
        app: my-frontend-app
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        # ... rest of config
```

```yaml
# After (stable for canary)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable  # Renamed
  namespace: canary-demo
  labels:
    app: my-frontend-app
    version: stable  # Added
spec:
  # strategy.type removed (defaults to RollingUpdate)
  replicas: 2
  selector:
    matchLabels:
      app: my-frontend-app
      version: stable  # Added
  template:
    metadata:
      labels:
        app: my-frontend-app
        version: stable  # Added
    spec:
      containers:
      - name: app
        image: myapp:1.0.0  # Current production image
        # ... rest of config unchanged
---
apiVersion: v1
kind: Service
metadata:
  name: stable-svc
  namespace: canary-demo
spec:
  selector:
    app: my-frontend-app
    version: stable
  ports:
  - port: 80
    targetPort: 8080
```

### Step 3: Create Canary Deployment (New Version)

Create a new Deployment for the new version:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
  namespace: canary-demo
  labels:
    app: my-frontend-app
    version: canary
spec:
  replicas: 1  # Start with 1 replica
  selector:
    matchLabels:
      app: my-frontend-app
      version: canary
  template:
    metadata:
      labels:
        app: my-frontend-app
        version: canary
    spec:
      containers:
      - name: app
        image: myapp:2.0.0  # New version
        # ... same config as stable (env vars, resources, etc.)
---
apiVersion: v1
kind: Service
metadata:
  name: canary-svc
  namespace: canary-demo
spec:
  selector:
    app: my-frontend-app
    version: canary
  ports:
  - port: 80
    targetPort: 8080
```

### Step 4: Update Ingress for Canary Routing

**If you have an existing Ingress:**

1. **Update** it to point to `stable-svc` (instead of your old service)
2. **Add** a new canary Ingress with the same host/path but canary annotations

**Example:**

```yaml
# Main Ingress (stable) - update your existing one
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-stable-ingress
  namespace: canary-demo
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: stable-svc  # Changed from old service
            port:
              number: 80
```

```yaml
# New Canary Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-canary-ingress
  namespace: canary-demo
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "X-User-Id"
    nginx.ingress.kubernetes.io/canary-by-header-pattern: "user-canary-001|user-canary-002"
spec:
  rules:
  - host: myapp.example.com  # Same host as stable
    http:
      paths:
      - path: /  # Same path as stable
        pathType: Prefix
        backend:
          service:
            name: canary-svc
            port:
              number: 80
```

### Step 5: Deploy in Order (No Downtime)

```bash
# 1. Deploy stable (your existing app, now labeled as stable)
kubectl apply -f k8s/base/stable.yaml

# 2. Verify stable is running (no downtime - your app keeps serving)
kubectl get pods -n canary-demo -l version=stable

# 3. Deploy canary (new version, separate deployment)
kubectl apply -f k8s/base/canary.yaml

# 4. Update ingress to stable service
kubectl apply -f k8s/base/ingress-stable.yaml

# 5. Add canary ingress (header-based routing)
kubectl apply -f k8s/base/ingress-canary.yaml
```

**Result:**
- ✅ Your existing app keeps running (no downtime)
- ✅ Most users continue to use stable (existing version)
- ✅ Only users with `X-User-Id` matching the pattern get canary (new version)

### Step 6: Test Canary

```bash
# Normal user (stable)
curl http://myapp.example.com/
# → Gets version 1.0.0 (stable)

# Canary user (new version)
curl -H "X-User-Id: user-canary-001" http://myapp.example.com/
# → Gets version 2.0.0 (canary)
```

## Migration Checklist

- [ ] Backup current Deployment YAML
- [ ] Identify current Service and Ingress
- [ ] Convert Deployment to stable (add labels, remove recreate strategy)
- [ ] Create stable Service selecting stable pods
- [ ] Create canary Deployment (new version)
- [ ] Create canary Service selecting canary pods
- [ ] Update existing Ingress to point to stable-svc
- [ ] Create canary Ingress with header-based routing
- [ ] Deploy stable first (verify no downtime)
- [ ] Deploy canary (verify pods start)
- [ ] Test routing (with/without X-User-Id header)
- [ ] Monitor canary metrics/errors
- [ ] Promote canary to stable when validated

## Rollback Plan

If something goes wrong during migration:

1. **Remove canary ingress** (all traffic goes back to stable):
   ```bash
   kubectl delete ingress app-canary-ingress -n canary-demo
   ```

2. **Scale down canary** (optional):
   ```bash
   kubectl scale deployment/app-canary --replicas=0 -n canary-demo
   ```

3. **Revert stable Deployment** to original if needed:
   ```bash
   kubectl apply -f current-deployment.yaml
   ```

No downtime - stable keeps serving throughout.

## Benefits After Migration

| Before (Recreate) | After (Canary) |
|-------------------|----------------|
| ❌ Downtime during updates | ✅ Zero downtime |
| ❌ All users see new version immediately | ✅ Gradual rollout to selected users |
| ❌ Hard to rollback | ✅ Instant rollback (remove canary ingress) |
| ❌ No way to test with real users | ✅ Test with real users before full rollout |
