@echo off
REM ============================================================
REM  One-click push: PFC Trainer -> GitHub (triggers CI to build IPA)
REM  Usage in cmd        : scripts\push-all.bat "v1.0.2 note"
REM  Usage in PowerShell : .\scripts\push-all.bat "v1.0.2 note"
REM  Repo: https://github.com/LiuHui66/Actions-ds
REM  NOTE: ASCII-only on purpose, so codepage never breaks parsing.
REM ============================================================
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0.."

set "REMOTE_URL=https://github.com/LiuHui66/Actions-ds.git"
set "MSG=%~1"
if "%MSG%"=="" set "MSG=update"

echo [0/6] checking git ...
git --version >nul 2>&1 || (echo [ERR] git not found - install from https://git-scm.com/download/win & pause & exit /b 1)

echo [1/6] init local repo ^(first run only^)
if not exist ".git" git init
git symbolic-ref HEAD refs/heads/main 2>nul

echo [2/6] checking remote origin
git remote get-url origin >nul 2>&1 || git remote add origin "%REMOTE_URL%"
git remote set-url origin "%REMOTE_URL%"

echo [3/6] checking git identity
git config user.name >nul 2>&1 || git config --global user.name "LiuHui66"
git config user.email >nul 2>&1 || git config --global user.email "liuhui66@users.noreply.github.com"

echo [4/6] commit
git add -A
git commit -m "%MSG%"
if errorlevel 1 (
  echo    [i] NOTHING NEW TO COMMIT - no file change was detected.
  echo    [i] If you DID change files, they were not saved where git looks.
)

echo [5/6] push to GitHub
git push -u origin main
if errorlevel 1 (
  echo.
  echo [ERR] push failed. Try in order:
  echo   1. proxy : git config --global http.proxy http://127.0.0.1:7890
  echo   2. token : use a Personal Access Token as the password
  echo   3. stale : cmdkey /delete:git:https://github.com
  pause
  exit /b 1
)

echo [6/6] verify local vs remote
for /f "delims=" %%i in ('git rev-parse HEAD') do set "LOCAL_SHA=%%i"
for /f "delims=" %%i in ('git ls-remote origin refs/heads/main') do set "REMOTE_LINE=%%i"
for /f "tokens=1" %%i in ("!REMOTE_LINE!") do set "REMOTE_SHA=%%i"
echo    local  : !LOCAL_SHA!
echo    remote : !REMOTE_SHA!
if /i "!LOCAL_SHA!"=="!REMOTE_SHA!" (
  echo    [OK] remote main == local HEAD, CI should start now
) else (
  echo    [WARN] remote main differs from local HEAD - the push did not land
)

echo.
echo === DONE ===
echo Version in this build:
type VERSION
echo.
echo Build progress : https://github.com/LiuHui66/Actions-ds/actions
echo IPA download   : https://github.com/LiuHui66/Actions-ds/releases
echo Install with Sideloadly on Windows.
pause
endlocal
