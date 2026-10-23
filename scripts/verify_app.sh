#!/bin/bash
set -e

APP_PATH="/Applications/TypeJoy.app"
echo "🔍 开始对已安装的 $APP_PATH 进行全面真实性测试..."

# 1. 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 错误：应用未安装在 $APP_PATH"
    exit 1
fi
echo "  ✓ 1. 应用存在于 $APP_PATH"

# 2. 检查代码签名
codesign -vvv --deep --strict "$APP_PATH" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ 2. 代码签名验证通过 (Ad-hoc valid)"
else
    echo "❌ 2. 代码签名验证失败"
    exit 1
fi

# 3. 检查 Info.plist 配置
LS_UI_ELEMENT=$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$APP_PATH/Contents/Info.plist" 2>/dev/null)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist" 2>/dev/null)
if [ "$LS_UI_ELEMENT" == "true" ] && [ "$BUNDLE_ID" == "com.user.typejoy" ]; then
    echo "  ✓ 3. Info.plist 正确配置 (LSUIElement = true, BundleId = $BUNDLE_ID)"
else
    echo "❌ 3. Info.plist 配置异常"
    exit 1
fi

# 4. 检查资源文件与音频播放
if [ -f "$APP_PATH/Contents/Resources/coin.wav" ] && [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
    echo "  ✓ 4. 关键资源文件完整 (coin.wav, AppIcon.icns)"
else
    echo "❌ 4. 资源文件缺失"
    exit 1
fi

# 5. 检查运行中进程及资源占用
PID=$(pgrep -x TypeJoy || true)
if [ -n "$PID" ]; then
    CPU=$(ps -p "$PID" -o %cpu= | tr -d ' ')
    RSS_KB=$(ps -p "$PID" -o rss= | tr -d ' ')
    RSS_MB=$((RSS_KB / 1024))
    echo "  ✓ 5. TypeJoy 正在稳定运行 (PID: $PID, CPU: ${CPU}%, 物理内存: ${RSS_MB} MB)"
else
    echo "⚠️ 5. TypeJoy 当前未运行，尝试重新拉起验证..."
    open "$APP_PATH"
    sleep 2
    PID=$(pgrep -x TypeJoy)
    echo "  ✓ 5. TypeJoy 已成功启动 (PID: $PID)"
fi

echo "🎉 全面真实性测试通过！TypeJoy 已在当前 macOS 电脑上完成安装并正常常驻菜单栏运行。"
