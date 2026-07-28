#!/system/bin/sh
#===============================================================================
# 清荷 - KSU 操作按钮 (action.sh)
# 点击后启动 Web UI 并自动打开浏览器
#===============================================================================

PORT="${1:-8848}"
MODDIR="/data/adb/modules/qinghe"

echo "启动清荷 Web UI..."
sh "$MODDIR/web/server.sh" "$PORT" &

sleep 1

if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://127.0.0.1:$PORT" >/dev/null 2>&1
fi
