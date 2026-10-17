@echo off
chcp 65001 >nul
REM ============================================================
REM  一键推送 PFC Trainer 到 GitHub（触发云端编译 IPA）
REM  用法：双击，或在 cmd 里运行：
REM        scripts\push-all.bat "v1.0.1 调整点错反馈"
REM  仓库：https://github.com/LiuHui66/Actions-ds
REM ============================================================
setlocal enabledelayedexpansion
cd /d "%~dp0.."

set REMOTE_URL=https://github.com/LiuHui66/Actions-ds.git
set MSG=%~1
if "%MSG%"=="" set MSG=update %DATE% %TIME%

REM 1) 首次使用：初始化本地仓库
if not exist ".git" (
  echo [1/4] 初始化本地 git 仓库...
  git init || goto :fail
  git branch -M main
)

REM 2) 确保 origin 指向目标仓库
git remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [2/4] 添加远端 origin = %REMOTE_URL%
  git remote add origin %REMOTE_URL% || goto :fail
) else (
  echo [2/4] 远端 origin 已存在，跳过
)

REM 3) 提交
echo [3/4] 提交改动：%MSG%
git add -A
git commit -m "%MSG%"

REM 4) 推送
echo [4/4] 推送到 GitHub...
git push -u origin main || goto :pushfail

echo.
echo === 完成 ===
echo 打开 https://github.com/LiuHui66/Actions-ds/actions 查看编译进度
echo 编译结束后在 Artifacts 里下载 PFC-^<版本^>-^<构建号^>.zip
goto :end

:pushfail
echo.
echo [ERR] 推送失败。常见原因：
echo   1) 网络问题：开代理后重试，或执行 git config --global http.proxy http://127.0.0.1:端口
echo   2) 认证失败：GitHub 已不支持密码，需用 Personal Access Token 作为密码
echo      生成地址 https://github.com/settings/tokens  （勾选 repo 权限）
goto :end

:fail
echo [ERR] 命令执行失败，请检查 git 是否已安装（git --version）

:end
echo.
pause
endlocal
