# Deploy stable + canary (user-based canary POC) to AKS
# Usage: .\deploy.ps1 -Namespace canary-demo [-UseArgoRollout]
#   UseArgoRollout: deploy Argo Rollout + Services instead of two Deployments
param(
    [string]$Namespace = "canary-demo",
    [string]$K8sDir = "$PSScriptRoot\..\k8s\base",
    [string]$ConfigDir = "$PSScriptRoot\..\k8s\config",
    [switch]$UseArgoRollout
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent   # aks-canary-user-based
$k8sRoot = Join-Path $repoRoot "k8s"

if ($UseArgoRollout) {
    Write-Host "Deploying canary-demo with Argo Rollouts to namespace: $Namespace" -ForegroundColor Cyan
    $argoDir = Join-Path $k8sRoot "argo-rollout"
    if (-not (Test-Path $argoDir)) { throw "Argo Rollout dir not found: $argoDir" }
    kubectl apply -k $argoDir
    if ($LASTEXITCODE -ne 0) { throw "kubectl apply -k failed" }
    Write-Host "Deploy done. Check: kubectl argo rollouts status canary-demo -n $Namespace" -ForegroundColor Cyan
    exit 0
}

$basePath = Resolve-Path $K8sDir
$configPath = Resolve-Path $ConfigDir
Write-Host "Deploying canary-demo to namespace: $Namespace" -ForegroundColor Cyan
Write-Host "K8s base: $basePath" -ForegroundColor Gray

# Order: namespace -> stable -> canary -> config -> ingresses
$manifests = @(
    "namespace.yaml",
    "stable.yaml",
    "canary.yaml"
)
foreach ($f in $manifests) {
    $path = Join-Path $basePath $f
    if (Test-Path $path) {
        Write-Host "Applying $f ..." -ForegroundColor Green
        kubectl apply -f $path
        if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed for $f" }
    }
}

if (Test-Path (Join-Path $configPath "canary-users.yaml")) {
    Write-Host "Applying config canary-users.yaml ..." -ForegroundColor Green
    kubectl apply -f (Join-Path $configPath "canary-users.yaml")
}

foreach ($f in @("ingress-stable.yaml", "ingress-canary.yaml")) {
    $path = Join-Path $basePath $f
    if (Test-Path $path) {
        Write-Host "Applying $f ..." -ForegroundColor Green
        kubectl apply -f $path
        if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed for $f" }
    }
}

Write-Host "Deploy done. Check: kubectl get pods -n $Namespace" -ForegroundColor Cyan
