# Test stable vs canary by calling the app with and without X-User-Id
# Usage: .\test-canary.ps1 -IngressHost "http://<IP>" [-CanaryUsers @("user-canary-001","user-canary-002")]
param(
    [Parameter(Mandatory=$true)]
    [string]$IngressHost,
    [string[]]$CanaryUsers = @("user-canary-001", "user-canary-002")
)

$ErrorActionPreference = "Stop"
$IngressHost = $IngressHost.TrimEnd("/")

Write-Host "Testing canary routing (Ingress: $IngressHost)" -ForegroundColor Cyan

# Request without canary header -> stable
Write-Host "`n1. Request WITHOUT X-User-Id (expect stable):" -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri $IngressHost -UseBasicParsing -TimeoutSec 10
    if ($r.Content -match "Version: 1 \(stable\)") { Write-Host "   OK - got stable" -ForegroundColor Green }
    elseif ($r.Content -match "Version: 2 \(canary\)") { Write-Host "   UNEXPECTED - got canary" -ForegroundColor Red }
    else { Write-Host "   Response: $($r.Content.Substring(0, [Math]::Min(200, $r.Content.Length)))..." -ForegroundColor Gray }
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Request with canary user ID -> canary
foreach ($uid in $CanaryUsers) {
    Write-Host "`n2. Request with X-User-Id: $uid (expect canary):" -ForegroundColor Yellow
    try {
        $headers = @{ "X-User-Id" = $uid }
        $r = Invoke-WebRequest -Uri $IngressHost -Headers $headers -UseBasicParsing -TimeoutSec 10
        if ($r.Content -match "Version: 2 \(canary\)") { Write-Host "   OK - got canary" -ForegroundColor Green }
        elseif ($r.Content -match "Version: 1 \(stable\)") { Write-Host "   UNEXPECTED - got stable" -ForegroundColor Red }
        else { Write-Host "   Response: $($r.Content.Substring(0, [Math]::Min(200, $r.Content.Length)))..." -ForegroundColor Gray }
    } catch {
        Write-Host "   Error: $_" -ForegroundColor Red
    }
}

# Request with random user ID -> stable
Write-Host "`n3. Request with X-User-Id: random-user-999 (expect stable):" -ForegroundColor Yellow
try {
    $headers = @{ "X-User-Id" = "random-user-999" }
    $r = Invoke-WebRequest -Uri $IngressHost -Headers $headers -UseBasicParsing -TimeoutSec 10
    if ($r.Content -match "Version: 1 \(stable\)") { Write-Host "   OK - got stable" -ForegroundColor Green }
    elseif ($r.Content -match "Version: 2 \(canary\)") { Write-Host "   UNEXPECTED - got canary" -ForegroundColor Red }
    else { Write-Host "   Response: $($r.Content.Substring(0, [Math]::Min(200, $r.Content.Length)))..." -ForegroundColor Gray }
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host "`nDone." -ForegroundColor Cyan
