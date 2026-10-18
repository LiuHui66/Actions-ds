# ============================================================
#  One-click push (PowerShell version, more reliable than .bat)
#  Run:  powershell -ExecutionPolicy Bypass -File .\scripts\push-all.ps1 "v1.0.1 note"
#  Or just: .\scripts\push-all.ps1 "note"
# ============================================================
param([string]$Message = "update")

$remote = "https://github.com/LiuHui66/Actions-ds.git"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERR] git not found - install from https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}

Write-Host "[1/5] init local repo (first run only)"
if (-not (Test-Path ".git")) { git init | Out-Null }
git symbolic-ref HEAD refs/heads/main 2>$null

Write-Host "[2/5] checking remote origin"
git remote get-url origin 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { git remote add origin $remote }
git remote set-url origin $remote

Write-Host "[3/5] checking git identity"
git config user.name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { git config --global user.name "LiuHui66" }
git config user.email 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { git config --global user.email "liuhui66@users.noreply.github.com" }

Write-Host "[4/5] commit"
git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Host "  (nothing to commit - fine, continuing)" -ForegroundColor Yellow }

Write-Host "[5/5] push to GitHub"
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERR] push failed. Try in order:" -ForegroundColor Red
    Write-Host "  1. proxy  : git config --global http.proxy http://127.0.0.1:7890"
    Write-Host "  2. auth   : use a Personal Access Token as the password"
    Write-Host "  3. stale  : cmdkey /delete:git:https://github.com"
    exit 1
}

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Get-Content VERSION | Out-Host
Write-Host ""
Write-Host "Build progress : https://github.com/LiuHui66/Actions-ds/actions"
Write-Host "IPA download   : https://github.com/LiuHui66/Actions-ds/releases"
