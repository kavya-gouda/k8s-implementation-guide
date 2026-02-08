# Promote canary to stable: update stable deployment to canary image and optionally remove canary
# Usage: .\promote-canary.ps1 -Namespace canary-demo -StableImage "myacr.azurecr.io/canary-demo:2" [-RemoveCanaryIngress]
param(
    [string]$Namespace = "canary-demo",
    [Parameter(Mandatory=$true)]
    [string]$StableImage,
    [switch]$RemoveCanaryIngress
)

$ErrorActionPreference = "Stop"

Write-Host "Promoting canary to stable in namespace: $Namespace" -ForegroundColor Cyan
Write-Host "Stable will use image: $StableImage" -ForegroundColor Gray

kubectl set image deployment/app-stable app=$StableImage -n $Namespace
if ($LASTEXITCODE -ne 0) { throw "Failed to set stable image" }

Write-Host "Waiting for stable rollout ..." -ForegroundColor Yellow
kubectl rollout status deployment/app-stable -n $Namespace --timeout=120s

if ($RemoveCanaryIngress) {
    Write-Host "Removing canary ingress (all traffic goes to stable) ..." -ForegroundColor Yellow
    kubectl delete ingress app-canary-ingress -n $Namespace --ignore-not-found
    Write-Host "Optional: scale down canary deployment: kubectl scale deployment/app-canary --replicas=0 -n $Namespace" -ForegroundColor Gray
}

Write-Host "Promotion complete. Stable now serves $StableImage" -ForegroundColor Green
