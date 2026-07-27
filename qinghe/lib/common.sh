#!/system/bin/sh
#===============================================================================
# 清荷 - 公共函数库
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QINGHE_HOME="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NO_COLOR=false
if [ "$TERM" = "dumb" ] || [ -z "$TERM" ]; then
    NO_COLOR=true
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_err() {
    echo -e "${RED}[ERR]${NC} $1" >&2
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_err "需要 Root 权限才能访问 /data/data/ 目录"
        log_err "请在 Root 环境下运行本工具"
        exit 1
    fi
}

detect_env() {
    RUN_ENV="unknown"

    ENV_MT="MT管理器"
    if [ -n "$MT_USER_DATA" ] || [ "$(basename "$SHELL")" = "m.sh" ] 2>/dev/null; then
        RUN_ENV="$ENV_MT"
    fi

    if echo "$PREFIX" 2>/dev/null | grep -q "com.termux"; then
        RUN_ENV="Termux"
    fi

    if [ -d "/data/adb/modules" ]; then
        MODULE_DIR="/data/adb/modules/qinghe"
        RUN_ENV="${RUN_ENV}/Module"
    fi

    export RUN_ENV
}

get_data_dir() {
    if [ -n "$QH_DATA_DIR" ]; then
        echo "$QH_DATA_DIR"
        return
    fi

    if [ -d "$MODULE_DIR" ] 2>/dev/null; then
        echo "/data/qinghe"
        return
    fi

    echo "$QINGHE_HOME/qinghe-data"
}

ensure_data_dirs() {
    DATA_DIR="$(get_data_dir)"
    ACCOUNTS_DIR="$DATA_DIR/accounts"
    SNAPSHOTS_DIR="$DATA_DIR/snapshots"

    mkdir -p "$ACCOUNTS_DIR" 2>/dev/null || true
    mkdir -p "$SNAPSHOTS_DIR" 2>/dev/null || true

    export DATA_DIR ACCOUNTS_DIR SNAPSHOTS_DIR
}

check_cmd() {
    _cmd="$1"
    if ! command -v "$_cmd" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

check_dependencies() {
    _missing=""

    for _cmd in cp mv rm tar gzip; do
        if ! check_cmd "$_cmd"; then
            _missing="$_missing $_cmd"
        fi
    done

    if [ -n "$_missing" ]; then
        log_err "缺少必需命令:$_missing"
        log_err "请安装 busybox 或对应工具包"
        exit 1
    fi

    if check_cmd "openssl"; then
        HAS_OPENSSL=true
    else
        HAS_OPENSSL=false
        log_warn "openssl 不可用, 加密功能将无法使用"
    fi

    if check_cmd "pgrep"; then
        HAS_PGREP=true
    else
        HAS_PGREP=false
    fi

    if check_cmd "pm"; then
        HAS_PM=true
    else
        HAS_PM=false
    fi

    export HAS_OPENSSL HAS_PGREP HAS_PM
}
