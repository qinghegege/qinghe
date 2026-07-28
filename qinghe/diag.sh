#!/system/bin/sh
#===============================================================================
# 清荷 - 诊断脚本 (手动在终端执行)
# 用法: sh /data/adb/modules/qinghe/diag.sh [包名]
#===============================================================================

PKG="${1:-com.tencent.tmgp.pubgmhd}"
LOG="/storage/emulated/0/qinghe_diag.log"

log() { echo "$1" >> "$LOG"; }

> "$LOG"
log "========== 清荷 v2.2.6 诊断 $(date) =========="
log "目标包名: $PKG"
log ""

# 1. 基础环境
log "--- [1] Shell 环境 ---"
log "SHELL=$SHELL"
log "sh version: $(sh --version 2>&1 | head -1 || echo 'unknown')"
log "id: $(id 2>&1 || echo 'unknown')"
log "busybox: $(which busybox 2>/dev/null || echo 'not found')"
log ""

# 2. 检查 /data/data 是否可读
log "--- [2] /data/data 目录 ---"
log "ls /data/data/ 前 5 项 (2s 超时):"
timeout 2 ls /data/data/ 2>&1 | head -5 >> "$LOG" || log "!! ls 超时或失败"
log ""

# 3. 逐个检查已知路径的 stat
log "--- [3] 逐路径 stat 检测 ---"

check_dir() {
    _dir="$1"
    _label="$2"
    printf "  [%s] %s ... " "$_label" "$_dir" >> "$LOG"
    # 用 timeout 2s 防止 stat 卡死
    _r=$(timeout 2 sh -c "[ -d \"$_dir\" ] && echo YES || echo NO" 2>&1)
    echo "$_r" >> "$LOG"
}

check_dir "/data/data/$PKG"          "p1"
check_dir "/data/user_de/0/$PKG"     "p2"
check_dir "/data/user/0/$PKG"        "p3"
check_dir "/data/misc/profiles/cur/0/$PKG" "p4"
log ""

# 4. ls /data/user 多用户分区
log "--- [4] 多用户分区扫描 ---"
log "ls /data/user/ (2s 超时):"
_uids=$(timeout 2 ls /data/user/ 2>&1)
log "  结果: $_uids"

if [ -n "$_uids" ]; then
    for _u in $_uids; do
        if [ "$_u" -eq "$_u" ] 2>/dev/null && [ "$_u" != "0" ]; then
            printf "  检查 user/%s ... " "$_u" >> "$LOG"
            _r=$(timeout 2 sh -c "[ -d \"/data/user/$_u/$PKG\" ] && echo YES || echo NO" 2>&1)
            echo "$_r" >> "$LOG"
        fi
    done
fi
log ""

# 5. 找 shared_prefs 验证包名真实路径
log "--- [5] 通过 shared_prefs 反查路径 ---"
log "搜索 $PKG 的 shared_prefs (2s 超时):"
_shpf=$(timeout 2 find /data/data /data/user_de -maxdepth 3 -type d -name "$PKG" 2>/dev/null | head -5)
if [ -z "$_shpf" ]; then
    log "  find /data/data 无结果"
else
    echo "$_shpf" >> "$LOG"
fi
log ""

# 6. 检查 get_param 函数是否正常
log "--- [6] CGI get_param 函数自检 ---"
QUERY_STRING="action=uids&pkg=$PKG"
_key="action"
for _pair in $(echo "$QUERY_STRING" | tr '&' ' '); do
    _k="${_pair%%=*}"
    [ "$_k" = "$_key" ] && _v="${_pair#*=}" && break
done
log "  get_param('action') = $_v"

_key="pkg"
for _pair in $(echo "$QUERY_STRING" | tr '&' ' '); do
    _k="${_pair%%=*}"
    [ "$_k" = "$_key" ] && _v="${_pair#*=}" && break
done
log "  get_param('pkg') = $_v"
log ""

# 7. json_ok 函数自检
log "--- [7] json_ok 函数自检 ---"
uids="\"0\""
json_ok() { echo "{\"ok\":true${1:+,$1}}"; }
log "  $(json_ok "\"uids\":[${uids}]")"
log ""

log "========== 诊断完成 =========="
echo "诊断日志已写入: $LOG"
echo "请查看文件内容: cat $LOG"