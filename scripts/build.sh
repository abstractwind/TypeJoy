#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="TypeJoy"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🚀 开始构建 $APP_NAME.app ..."

# 1. 清理旧构建并创建 Bundle 目录结构
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 2. 复制资源文件
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIR/Resources/coin.wav" "$APP_BUNDLE/Contents/Resources/coin.wav"

# 3. 编译 Swift 源码
echo "📦 正在编译 Swift 源代码..."
swiftc \
    -O \
    -target arm64-apple-macos13.0 \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "$PROJECT_DIR/Sources/"*.swift

# 4. 本地 Ad-hoc 签名
echo "✍️ 正在进行本地代码签名..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ 构建成功！应用位于:"
echo "$APP_BUNDLE"
