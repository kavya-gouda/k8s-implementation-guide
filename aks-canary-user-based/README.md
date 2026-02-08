# Canary Progressive Deployment (User-Based) on AKS – POC

**Self-contained POC.** Everything you need is in this folder; no references to or dependency on other repo folders.

**Your context:** Application is deployed with **Argo CD** (GitOps) and uses **Recreate strategy** only. This POC shows how to move to **user-based canary** with **no downtime**: only selected user IDs see the new version; the rest stay on stable.

End-to-end proof of concept for **user-ID-based canary deployment** on Azure Kubernetes Service (AKS). New versions are exposed only to a configured subset of users (by user ID).

## Requirements Addressed

| Requirement | Solution |
|-------------|----------|
| **Argo CD + Recreate today** | Migrate to canary; Argo CD continues to sync manifests from Git (this POC or your fork) |
| **Existing app uses Recreate strategy** | Replace with **stable** + canary (remove Recreate); or use a single **Rollout** with canary strategy |
| New version only for subset of users | NGINX Ingress **canary-by-header** / **canary-by-header-pattern** routes by `X-User-Id` |
| No downtime | Stable stays live; canary is additive; promotion is a traffic switch |

## Tooling (AKS-Native, all in this POC)

- **NGINX Ingress Controller** – Header-based canary routing (AKS [Application Routing add-on](https://learn.microsoft.com/en-us/azure/aks/app-routing-nginx) or [NGINX Ingress Controller](https://learn.microsoft.com/en-us/azure/aks/ingress-basic))
- **Option A:** Two **Deployments** + Services (stable + canary) – apply manifests in `k8s/base/`
- **Option B:** **Argo Rollouts** – One Rollout + two Services; controller manages selectors. Manifests in `k8s/argo-rollout/`. Works with Argo CD (Argo CD syncs the Rollout instead of a Deployment)

## Quick Start

1. **Prerequisites**: AKS cluster, `kubectl` configured, NGINX Ingress Controller installed.
2. **Deploy** (choose one):
   - **With Argo Rollouts** (single Rollout, controller-managed Services):
     ```bash
     kubectl apply -k k8s/argo-rollout
     ```
     Or: `./scripts/deploy.ps1 -Namespace canary-demo -UseArgoRollout`
   - **With plain Deployments** (two Deployments + Services):
     ```bash
     ./scripts/deploy.ps1 -Namespace canary-demo
     ```
3. **Request as normal user** (stable):
   ```bash
   curl -s http://<INGRESS_IP>/  # or with Host header
   # Response indicates "Version: 1 (stable)"
   ```
4. **Request as canary user** (header `X-User-Id` in allowed list):
   ```bash
   curl -s -H "X-User-Id: user-canary-001" http://<INGRESS_IP>/
   # Response indicates "Version: 2 (canary)"
   ```

**Argo CD:** Point your Argo CD Application at this repo (or the path that contains this POC). After migration, Argo CD syncs either the base manifests (two Deployments) or the Argo Rollout manifests; no Recreate strategy, no downtime.

**[→ End-to-End Setup Guide](./docs/00-Setup-Guide-End-to-End.md)** — Single guide to run the full POC (prerequisites → deploy → test stable/canary → promote or rollback).

See also [Architecture](./docs/01-Architecture.md) and [Runbook](./docs/02-Runbook.md).

## Repository Layout

```
aks-canary-user-based/
├── README.md                    # This file
├── docs/
│   ├── 00-Setup-Guide-End-to-End.md  # Single guide: run full POC from scratch
│   ├── 01-Architecture.md       # Architecture and diagrams
│   ├── 02-Runbook.md            # Deploy, test, promote, rollback
│   ├── 03-Migrate-From-Recreate.md  # Migration: Recreate → Canary
│   └── 04-Migrate-To-Argo-Rollouts.md  # Migration to Argo Rollouts
├── sample-app/
│   ├── Dockerfile               # Build v1 and v2 images (APP_VERSION build-arg)
│   ├── app/
│   │   ├── server.js            # Node app (echoes version + X-User-Id)
│   │   └── package.json
│   └── ...
├── k8s/
│   ├── base/                    # Option A: Stable + Canary as Deployments
│   │   ├── namespace.yaml
│   │   ├── stable.yaml          # Deployment + Service (version 1)
│   │   ├── canary.yaml          # Deployment + Service (version 2)
│   │   ├── ingress-stable.yaml  # Main Ingress (stable backend)
│   │   └── ingress-canary.yaml  # Canary Ingress (header-based)
│   ├── argo-rollout/            # Option B: Argo Rollouts (single Rollout + Services)
│   │   ├── rollout.yaml        # Rollout with canary strategy
│   │   ├── services.yaml       # stable-svc, canary-svc (controller-managed)
│   │   ├── analysis-template.yaml  # Optional metrics-based promote/abort
│   │   └── kustomization.yaml
│   └── config/
│       └── canary-users.yaml    # ConfigMap: list of canary user IDs (optional)
├── scripts/
│   ├── deploy.ps1               # Deploy/update stable + canary
│   ├── test-canary.ps1          # Curl tests with/without X-User-Id
│   ├── promote-canary.ps1       # Promote canary to stable (example)
│   └── migrate-from-recreate.ps1  # Helper: convert recreate Deployment to stable
└── workflows/
    └── canary-deploy.yml        # Example GitHub Actions canary workflow
```

## Sample User IDs (POC)

- **Canary users** (see new version): `user-canary-001`, `user-canary-002`  
  Configured in Ingress via `canary-by-header-pattern` (regex) or in ConfigMap for reference.
- **All other users**: Receive **stable** (existing) version.

## Next Steps

- **[End-to-End Setup Guide](./docs/00-Setup-Guide-End-to-End.md)** — Run the full demo from scratch (recommended to show the POC)
- [Migration from Argo CD + Recreate → Canary](./docs/03-Migrate-From-Recreate.md) (remove Recreate, add canary)
- [Use Argo Rollouts with Argo CD](./docs/04-Migrate-To-Argo-Rollouts.md) (single Rollout, promote/abort)
- [Architecture](./docs/01-Architecture.md) · [Runbook](./docs/02-Runbook.md) · [Example pipeline](./workflows/canary-deploy.yml)
