#!/system/bin/sh
#===============================================================================
# 清荷 - 通用工具
#===============================================================================

QH_VERSION="v2.2.0"
SAVE_DIR="/storage/emulated/0/账号存放位置"
ACCOUNT_DIRS="databases shared_prefs files no_backup app_webview"

GREEN='\033[38;2;101;194;148m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

log() { echo "[清荷] $1"; }
die() { echo -e "${RED}[清荷] $1${RESET}"; exit 1; }
info() { echo -e "${GREEN}$1${RESET}"; }
warn() { echo -e "${YELLOW}$1${RESET}"; }

require_root() {
    [ "$(id -u)" = "0" ] || die "需要 root 权限"
}
