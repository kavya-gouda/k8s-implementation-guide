# Canary Progressive Deployment (User-Based) on AKS – POC

End-to-end proof of concept for **user-ID-based canary deployment** on Azure Kubernetes Service (AKS). New versions are exposed only to a configured subset of users (by user ID) with **no downtime** for existing traffic.

## Requirements Addressed

| Requirement | Solution |
|-------------|----------|
| **Existing app uses Recreate strategy** | Convert to **stable** deployment (remove recreate strategy); canary is an additional deployment |
| Existing app under canary | Current app remains as **stable** deployment; canary is an additional deployment |
| New version only for subset of users | NGINX Ingress **canary-by-header** / **canary-by-header-pattern** routes by `X-User-Id` |
| Implement in existing deployment | Same host/path; canary Ingress + canary Deployment added alongside stable |
| No downtime | Stable stays live; canary is additive; promotion is a traffic switch |

## Tooling (AKS-Native)

- **NGINX Ingress Controller** – Header-based canary routing (AKS [Application Routing add-on](https://learn.microsoft.com/en-us/azure/aks/app-routing-nginx) or [NGINX Ingress Controller](https://learn.microsoft.com/en-us/azure/aks/ingress-basic))
- **Kubernetes Deployments + Services** – Stable (existing) and Canary (new version)
- **Optional**: Argo Rollouts for automated canary steps and promotion (can coexist with header-based routing)

## Quick Start

1. **Prerequisites**: AKS cluster, `kubectl` configured, NGINX Ingress Controller installed.
2. **Deploy stable (existing app)** and canary (new version):
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

See [Architecture](./docs/01-Architecture.md) and [Runbook](./docs/02-Runbook.md) for details.

## Repository Layout

```
aks-canary-user-based/
├── README.md                    # This file
├── docs/
│   ├── 01-Architecture.md       # Architecture and diagrams
│   ├── 02-Runbook.md            # Deploy, test, promote, rollback
│   └── 03-Migrate-From-Recreate.md  # Migration guide: Recreate → Canary
├── sample-app/
│   ├── Dockerfile               # Build v1 and v2 images (APP_VERSION build-arg)
│   ├── app/
│   │   ├── server.js            # Node app (echoes version + X-User-Id)
│   │   └── package.json
│   └── ...
├── k8s/
│   ├── base/                    # Stable (existing) + Canary resources
│   │   ├── namespace.yaml
│   │   ├── stable.yaml          # Deployment + Service (version 1)
│   │   ├── canary.yaml          # Deployment + Service (version 2)
│   │   ├── ingress-stable.yaml  # Main Ingress (stable backend)
│   │   └── ingress-canary.yaml  # Canary Ingress (header-based)
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

- **[Migration Guide: Recreate → Canary](./docs/03-Migrate-From-Recreate.md)** ← **Start here if migrating from recreate strategy**
- [Architecture and components](./docs/01-Architecture.md)
- [Deploy, test, and promote](./docs/02-Runbook.md)
- [Example pipeline](./workflows/canary-deploy.yml)
