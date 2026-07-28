#!/system/bin/sh
#===============================================================================
# 清荷 - Web 服务启动脚本
#===============================================================================

WEB_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT="${1:-8848}"
CONF_FILE="/tmp/qinghe_httpd.conf"

cat > "$CONF_FILE" << EOF
/cgi-bin/*:/system/bin/sh
EOF

echo "[清荷] 启动 Web 服务: http://127.0.0.1:$PORT"
echo "[清荷] 按 Ctrl+C 停止"

busybox httpd -p "$PORT" -h "$WEB_DIR" -c "$CONF_FILE" -f
