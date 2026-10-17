#!/usr/bin/env bash
# 无签名 IPA 构建脚本
# 运行环境：macOS + Xcode（GitHub Actions 的 macos runner / 云端 Mac / 朋友的 Mac 均可）
# 产出：export/PFC-<版本>-<构建号>.ipa（未签名，交给 Sideloadly 用免费 Apple ID 签）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION_FILE="VERSION"
if [ ! -f "$VERSION_FILE" ]; then
  echo "❌ 找不到 VERSION 文件"
  exit 1
fi

MARKETING_VERSION="$(grep -E '^MARKETING_VERSION=' "$VERSION_FILE" | head -n1 | cut -d= -f2 | tr -d '[:space:]')"
BUILD_NUMBER="$(grep -E '^BUILD_NUMBER=' "$VERSION_FILE" | head -n1 | cut -d= -f2 | tr -d '[:space:]')"

if [ -z "$MARKETING_VERSION" ] || [ -z "$BUILD_NUMBER" ]; then
  echo "❌ VERSION 文件格式错误，需要 MARKETING_VERSION 和 BUILD_NUMBER"
  exit 1
fi

echo "==> 构建版本 ${MARKETING_VERSION} (${BUILD_NUMBER})"

# 1) 生成 Xcode 工程
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "==> 未检测到 xcodegen，正在安装..."
  brew install xcodegen
fi
xcodegen generate

# 2) 清理
rm -rf "$ROOT/build" "$ROOT/export"

# 3) Release 无签名编译
xcodebuild \
  -project PFC.xcodeproj \
  -scheme PFC \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$ROOT/build" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$ROOT/build/Build/Products/Release-iphoneos/PFC.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ 编译产物不存在：$APP_PATH"
  exit 1
fi

# 4) 打包成 IPA（-y 保留符号链接，否则部分 App 会装不上）
mkdir -p "$ROOT/export/Payload"
cp -R "$APP_PATH" "$ROOT/export/Payload/"
IPA_NAME="PFC-${MARKETING_VERSION}-${BUILD_NUMBER}.ipa"
(cd "$ROOT/export" && zip -qry "$IPA_NAME" Payload)

echo "==> ✅ 完成：$ROOT/export/$IPA_NAME"
echo "==> 下一步：下载后用 Sideloadly 用免费 Apple ID 签名安装（详见 README）"
