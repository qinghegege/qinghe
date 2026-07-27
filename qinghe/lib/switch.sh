#!/system/bin/sh
#===============================================================================
# 清荷 - 切换引擎
#===============================================================================

check_game_running() {
    _pkg="$1"

    if [ "$HAS_PGREP" = true ]; then
        pgrep -f "$_pkg" >/dev/null 2>&1 && return 0
    else
        ps -A 2>/dev/null | grep -q "$_pkg" && return 0
        ps 2>/dev/null | grep -q "$_pkg" && return 0
    fi

    return 1
}

backup_current_snapshot() {
    _game="$1"
    _path="$2"

    _ts="$(date '+%Y%m%d%H%M%S')"
    _snapshot_dir="$SNAPSHOTS_DIR/$_game/snapshot_$_ts"

    if [ ! -d "$_path" ]; then
        log_warn "数据目录不存在, 跳过快照: $_path"
        return 0
    fi

    mkdir -p "$_snapshot_dir/data"
    cp -r "$_path"/. "$_snapshot_dir/data/" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_info "自动快照已保存: snapshot_$_ts"
    else
        log_warn "自动快照保存失败"
    fi

    echo "$_snapshot_dir"
    return 0
}

apply_backup() {
    _alias="$1"

    _meta="$(find "$ACCOUNTS_DIR" -name meta.json -exec grep -l "\"alias\": *\"$_alias\"" {} \; 2>/dev/null | head -1)"

    if [ -z "$_meta" ] || [ ! -f "$_meta" ]; then
        log_err "备份不存在: $_alias"
        return 1
    fi

    _acct_dir="$(dirname "$_meta")"
    _data_dir="$_acct_dir/data"

    if [ ! -d "$_data_dir" ]; then
        log_err "备份数据损坏: data 目录缺失"
        return 1
    fi

    _target_path="$(grep '"path"' "$_meta" | head -1 | sed 's/.*"path": *"//;s/".*//')"

    if [ -z "$_target_path" ]; then
        log_err "元数据中缺少目标路径"
        return 1
    fi

    find "$_target_path" -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null
    cp -r "$_data_dir"/. "$_target_path/" 2>/dev/null

    if [ $? -ne 0 ]; then
        log_err "数据恢复失败"
        return 1
    fi

    return 0
}

fix_permissions() {
    _path="$1"
    _pkg="$2"

    if [ -n "$_pkg" ] && [ -d "$_path" ]; then
        _uid="$(stat -c '%u' "$_path" 2>/dev/null || echo "")"
        _gid="$(stat -c '%g' "$_path" 2>/dev/null || echo "")"

        if [ -n "$_uid" ] && [ "$_uid" != "0" ]; then
            chown -R "$_uid":"$_gid" "$_path" 2>/dev/null || true
        fi
    fi

    restorecon -R "$_path" 2>/dev/null || true
    chmod -R 755 "$_path" 2>/dev/null || true

    log_info "权限已修复"
}

rollback() {
    _game="$1"
    _path="$2"

    _latest_snapshot="$(ls -dt "$SNAPSHOTS_DIR/$_game"/snapshot_* 2>/dev/null | head -1)"

    if [ -z "$_latest_snapshot" ] || [ ! -d "$_latest_snapshot" ]; then
        log_err "无可用快照进行回滚"
        return 1
    fi

    _data_dir="$_latest_snapshot/data"
    if [ ! -d "$_data_dir" ]; then
        log_err "快照数据损坏"
        return 1
    fi

    find "$_path" -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null
    cp -r "$_data_dir"/. "$_path/" 2>/dev/null

    if [ $? -ne 0 ]; then
        log_err "回滚失败"
        return 1
    fi

    log_ok "已回滚到快照: $(basename "$_latest_snapshot")"
    return 0
}

switch_account() {
    _alias="$1"

    log_info "切换账号: $_alias"

    _meta="$(find "$ACCOUNTS_DIR" -name meta.json -exec grep -l "\"alias\": *\"$_alias\"" {} \; 2>/dev/null | head -1)"

    if [ -z "$_meta" ] || [ ! -f "$_meta" ]; then
        log_err "备份不存在: $_alias"
        return 1
    fi

    _game="$(grep '"game"' "$_meta" | head -1 | sed 's/.*"game": *"//;s/".*//')"
    _pkg="$(grep '"pkg"' "$_meta" | head -1 | sed 's/.*"pkg": *"//;s/".*//')"
    _target_path="$(grep '"path"' "$_meta" | head -1 | sed 's/.*"path": *"//;s/".*//')"
    _display="$(grep '"display"' "$_meta" | head -1 | sed 's/.*"display": *"//;s/".*//')"

    echo ""
    log_info "目标账号信息:"
    echo "  别名: $_alias"
    echo "  游戏: $_display"
    echo "  路径: $_target_path"
    echo ""

    if check_game_running "$_pkg"; then
        log_err "游戏进程正在运行, 请先关闭游戏"
        log_err "可在设置中强制停止, 或在终端执行: pkill $_pkg"
        return 1
    fi

    backup_current_snapshot "$_game" "$_target_path"

    if apply_backup "$_alias"; then
        fix_permissions "$_target_path" "$_pkg"
        log_ok "切换成功: $_alias"
        return 0
    else
        log_err "切换失败, 尝试回滚..."
        rollback "$_game" "$_target_path"
        return 1
    fi
}
