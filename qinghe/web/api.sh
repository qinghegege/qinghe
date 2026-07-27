#!/system/bin/sh
#===============================================================================
# 清荷 - Web API (CGI + CLI 双模)
# CGI: ?action=xxx + POST body
# CLI: api.sh <port> 启动内置 HTTP 服务器
#===============================================================================

API_DIR="$(cd "$(dirname "$0")" && pwd)"
QINGHE_HOME="$(dirname "$API_DIR")"

export QH_DATA_DIR="${QH_DATA_DIR:-}"

. "$QINGHE_HOME/lib/common.sh"
. "$QINGHE_HOME/lib/games.sh"
. "$QINGHE_HOME/lib/detect.sh"
. "$QINGHE_HOME/lib/crypto.sh"
. "$QINGHE_HOME/lib/account.sh"
. "$QINGHE_HOME/lib/switch.sh"

ensure_data_dirs

detect_env 2>/dev/null || true
check_dependencies

http_get_param() {
    _key="$1"
    _default="$2"
    _val=""

    if [ "$REQUEST_METHOD" = "POST" ] && [ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        _body="$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)"
        _val="$(echo "$_body" | sed 's/&/\n/g' | grep "^${_key}=" | head -1 | sed "s/^${_key}=//" | sed 's/+/ /g')"
    fi

    if [ -z "$_val" ] && [ -n "$QUERY_STRING" ]; then
        _val="$(echo "$QUERY_STRING" | sed 's/&/\n/g' | grep "^${_key}=" | head -1 | sed "s/^${_key}=//" | sed 's/+/ /g')"
    fi

    if [ -z "$_val" ]; then
        echo "$_default"
    else
        echo "$_val"
    fi
}

url_decode() {
    echo "$1" | sed 's/%20/ /g;s/%22/"/g;s/%2F/\//g;s/%3A/:/g;s/%2C/,/g;s/%7B/{/g;s/%7D/}/g'
}

cgi_header() {
    echo "Content-Type: application/json"
    echo "Access-Control-Allow-Origin: *"
    echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
    echo "Access-Control-Allow-Headers: Content-Type"
    echo ""
}

cgi_ok() {
    cgi_header
    echo "$1"
}

cgi_err() {
    cgi_header
    echo "{\"error\":\"$1\"}"
}

if [ "$REQUEST_METHOD" = "OPTIONS" ]; then
    cgi_header
    echo "{}"
    exit 0
fi

if [ -n "$REQUEST_METHOD" ]; then
    MODE="cgi"
    _action="$(http_get_param action "")"

    getp() { http_get_param "$@"; }
    respond() { cgi_ok "$1"; }
    respond_err() { cgi_err "$1"; }

    _selinux="$(getenforce 2>/dev/null || echo 'unknown')"
    if [ "$_selinux" = "Enforcing" ]; then
        echo "[WARN] SELinux Enforcing" >&2
    fi
else
    MODE="cli"
    _action="$1"
    shift 2>/dev/null

    _TMP_ARGS="/tmp/qh_api_args_$$"
    printf '%s\n' "$@" > "$_TMP_ARGS"
    trap "rm -f $_TMP_ARGS 2>/dev/null" EXIT

    getp() {
        _key="$1"
        _default="$2"
        while IFS= read -r _a 2>/dev/null; do
            case "$_a" in
                "${_key}="*) echo "${_a#${_key}=}"; return ;;
            esac
        done < "$_TMP_ARGS"
        echo "$_default"
    }
    respond() { echo "$1"; }
    respond_err() { echo "{\"error\":\"$1\"}"; }
fi

log_api() {
    echo "[$(date '+%H:%M:%S')] API: $_action" >&2
}

log_api

case "$_action" in
    detect)
        _result="$(detect_all_entries)"
        respond "{\"games\":$_result}"
        ;;

    accounts)
        _game="$(getp game "")"
        _path="$(getp path "")"
        _result="$(account_list "$_game" "$_path")"
        respond "{\"accounts\":$_result}"
        ;;

    backup)
        _g="$(getp game "")"
        _a="$(getp alias "")"
        _p="$(getp path "")"
        _md="$(getp mode "custom")"

        if [ -z "$_g" ] || [ -z "$_a" ]; then
            respond_err "参数缺失: 需要 game 和 alias"
            break
        fi

        _elog="/tmp/qh_bak_$$.log"
        if account_backup "$_g" "$_a" "$_p" "$_md" >"$_elog" 2>&1; then
            rm -f "$_elog"
            respond "{\"ok\":true,\"alias\":\"$_a\"}"
        else
            _tl="$(tail -2 "$_elog" 2>/dev/null | tr '\n' ' | ' | sed 's/"/\\\\"/g')"
            rm -f "$_elog"
            respond_err "${_tl:-备份失败}"
        fi
        ;;

    restore)
        _a="$(getp alias "")"

        if [ -z "$_a" ]; then
            respond_err "参数缺失: 需要 alias"
            break
        fi

        _elog="/tmp/qh_res_$$.log"
        if switch_account "$_a" >"$_elog" 2>&1; then
            rm -f "$_elog"
            respond "{\"ok\":true,\"alias\":\"$_a\"}"
        else
            _tl="$(tail -2 "$_elog" 2>/dev/null | tr '\n' ' | ' | sed 's/"/\\\\"/g')"
            rm -f "$_elog"
            respond_err "${_tl:-恢复失败}"
        fi
        ;;

    delete)
        _a="$(getp alias "")"

        if [ -z "$_a" ]; then
            respond_err "参数缺失: 需要 alias"
            break
        fi

        _elog="/tmp/qh_del_$$.log"
        if account_delete "$_a" 1 >"$_elog" 2>&1; then
            rm -f "$_elog"
            respond "{\"ok\":true,\"alias\":\"$_a\"}"
        else
            _tl="$(tail -2 "$_elog" 2>/dev/null | tr '\n' ' | ' | sed 's/"/\\\\"/g')"
            rm -f "$_elog"
            respond_err "${_tl:-删除失败}"
        fi
        ;;

    status)
        _se="$(getenforce 2>/dev/null || echo 'unknown')"
        respond "{\"ok\":true,\"version\":\"1.0.0\",\"dataDir\":\"$DATA_DIR\",\"selinux\":\"$_se\"}"
        ;;

    *)
        respond_err "未知接口: $_action"
        ;;
esac

exit 0
