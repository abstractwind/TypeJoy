#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="TypeJoy"
TARGET_DIR="/Applications"
TARGET_APP="$TARGET_DIR/$APP_NAME.app"

echo "🚀 开始安装 $APP_NAME 到 $TARGET_DIR ..."

# 1. 确保最新构建
"$SCRIPT_DIR/build.sh"

# 2. 如果已在运行，提示或优雅关闭
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "⚠️ 检测到 $APP_NAME 正在运行，正在准备更新..."
    killall "$APP_NAME" 2>/dev/null || true
    sleep 1
fi

# 3. 复制到 /Applications
echo "📦 正在拷贝应用到 $TARGET_APP ..."
rm -rf "$TARGET_APP"
cp -R "$BUILD_DIR/$APP_NAME.app" "$TARGET_APP"

# 4. 清理隔离属性
xattr -r -d com.apple.quarantine "$TARGET_APP" 2>/dev/null || true

echo "✅ 安装成功！应用已就绪: $TARGET_APP"
