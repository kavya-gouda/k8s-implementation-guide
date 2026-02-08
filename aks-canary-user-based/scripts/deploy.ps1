# Deploy stable + canary (user-based canary POC) to AKS
# Usage: .\deploy.ps1 -Namespace canary-demo [-K8sDir "..\k8s\base"]
param(
    [string]$Namespace = "canary-demo",
    [string]$K8sDir = "$PSScriptRoot\..\k8s\base",
    [string]$ConfigDir = "$PSScriptRoot\..\k8s\config"
)

$ErrorActionPreference = "Stop"
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
