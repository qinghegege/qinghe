#!/system/bin/sh
#===============================================================================
# 清荷 - Web 服务启动脚本
# 自动选择 busybox httpd 或纯 Shell HTTP 服务器
#===============================================================================

WEB_DIR="$(cd "$(dirname "$0")" && pwd)"
QINGHE_HOME="$(dirname "$WEB_DIR")"
PORT="${1:-8848}"
PID_FILE="/tmp/qinghe_web.pid"
LOG_FILE="/tmp/qinghe_web.log"

. "$QINGHE_HOME/lib/common.sh"
. "$QINGHE_HOME/lib/games.sh"

ensure_data_dirs

echo "=========================================="
echo "  清荷 Web UI"
echo "  http://127.0.0.1:$PORT"
echo "=========================================="

cleanup() {
    rm -f "$PID_FILE" 2>/dev/null
    echo ""
    echo "[INFO] Web 服务已关闭"
    exit 0
}

trap cleanup INT TERM HUP

start_with_httpd() {
    _doc_root="/tmp/qinghe_www"

    mkdir -p "$_doc_root/cgi-bin" 2>/dev/null
    cp "$WEB_DIR/api.sh" "$_doc_root/cgi-bin/api" 2>/dev/null
    cp "$WEB_DIR/index.html" "$_doc_root/index.html" 2>/dev/null
    chmod +x "$_doc_root/cgi-bin/api" 2>/dev/null

    cat > "$_doc_root/httpd.conf" <<CONF
$_doc_root
A:*
*.sh:/system/bin/sh
CONF

    echo "[INFO] 使用 busybox httpd 启动..."

    start_auto_shutdown_timer &
    busybox httpd -p "$PORT" -h "$_doc_root" -c "$_doc_root/httpd.conf" -f 2>/dev/null &
    echo $! > "$PID_FILE"
    wait $!
}

start_with_shell() {
    echo "[INFO] busybox httpd 不可用, 使用内置 HTTP 服务器..."

    start_auto_shutdown_timer &
    exec sh "$WEB_DIR/api.sh" "$PORT" 2>/dev/null
}

start_auto_shutdown_timer() {
    IDLE_TIMEOUT=120
    _last_activity="$(date +%s)"

    while true; do
        sleep 5
        _now="$(date +%s)"

        if [ -f "$LOG_FILE" ]; then
            _log_time="$(stat -c '%Y' "$LOG_FILE" 2>/dev/null || echo "$_last_activity")"
            if [ "$_log_time" -gt "$_last_activity" ]; then
                _last_activity="$_log_time"
            fi
        fi

        _idle=$(( _now - _last_activity ))
        if [ $_idle -ge $IDLE_TIMEOUT ]; then
            echo "[INFO] Web 服务已闲置 ${IDLE_TIMEOUT} 秒, 自动关闭" >&2
            _pid="$(cat "$PID_FILE" 2>/dev/null)"
            [ -n "$_pid" ] && kill "$_pid" 2>/dev/null
            rm -f "$PID_FILE" 2>/dev/null
            exit 0
        fi
    done
}

if command -v busybox >/dev/null 2>&1 && busybox httpd --help >/dev/null 2>&1; then
    start_with_httpd
else
    start_with_shell
fi
