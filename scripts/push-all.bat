@echo off
REM ============================================================
REM  One-click push: PFC Trainer -> GitHub (triggers CI to build IPA)
REM  Usage in cmd        : scripts\push-all.bat "v1.0.1 note"
REM  Usage in PowerShell : .\scripts\push-all.bat "v1.0.1 note"
REM  Repo: https://github.com/LiuHui66/Actions-ds
REM  NOTE: ASCII-only on purpose, so codepage never breaks parsing.
REM ============================================================
setlocal
chcp 65001 >nul
cd /d "%~dp0.."

set "REMOTE_URL=https://github.com/LiuHui66/Actions-ds.git"
set "MSG=%~1"
if "%MSG%"=="" set "MSG=update"

echo [0/5] checking git ...
git --version >nul 2>&1 || (echo [ERR] git not found - install from https://git-scm.com/download/win & pause & exit /b 1)

echo [1/5] init local repo (first run only)
if not exist ".git" git init
git symbolic-ref HEAD refs/heads/main 2>nul

echo [2/5] checking remote origin
git remote get-url origin >nul 2>&1 || git remote add origin "%REMOTE_URL%"
git remote set-url origin "%REMOTE_URL%"

echo [3/5] checking git identity
git config user.name >nul 2>&1 || git config --global user.name "LiuHui66"
git config user.email >nul 2>&1 || git config --global user.email "liuhui66@users.noreply.github.com"

echo [4/5] commit
git add -A
git commit -m "%MSG%"
echo    ^(if it says "nothing to commit", that is fine - keep going^)

echo [5/5] push to GitHub
git push -u origin main || (echo. & echo [ERR] push failed. Try in order: & echo   1. proxy: git config --global http.proxy http://127.0.0.1:7890 & echo   2. credential: use a Personal Access Token as the password & echo   3. stale credential: cmdkey /delete:git:https://github.com & pause & exit /b 1)

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
