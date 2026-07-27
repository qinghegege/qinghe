#!/system/bin/sh
#===============================================================================
# 清荷 - 账号管理模块
#===============================================================================

generate_auto_alias() {
    _ts="$(date '+%Y%m%d-%H%M%S')"
    echo "自动备份-$_ts"
}

path_hash() {
    _path="$1"
    echo "$_path" | md5sum 2>/dev/null | cut -d' ' -f1 | head -c8
    if [ -z "$_hash" ]; then
        echo "$_path" | sha256sum 2>/dev/null | cut -d' ' -f1 | head -c8
    fi
    if [ -z "$_hash" ]; then
        echo "$_path" | sed 's/[^a-zA-Z0-9]/_/g' | head -c16
    fi
}

account_backup() {
    _game="$1"
    _alias="$2"
    _src_path="$3"
    _mode="${4:-custom}"

    if ! is_valid_game "$_game"; then
        log_err "未知游戏: $_game"
        return 1
    fi

    if [ -z "$_src_path" ]; then
        _src_path="$(get_data_path "$_game")"
    fi

    if [ ! -d "$_src_path" ]; then
        log_err "游戏数据目录不存在: $_src_path"
        return 1
    fi

    _display="$(get_display_name "$_game")"
    _pkg="$(get_pkg_name "$_game")"

    _phash="$(path_hash "$_src_path")"
    _target_dir="$ACCOUNTS_DIR/$_game/$_phash/$_alias"

    if [ -d "$_target_dir" ]; then
        log_err "备份 '$_alias' 已存在, 请更换名称"
        return 1
    fi

    mkdir -p "$_target_dir/data"

    log_info "备份中..."
    log_info "  游戏: $_display"
    log_info "  来源: $_src_path"
    log_info "  别名: $_alias"
    log_info "  模式: $_mode"

    cp -r "$_src_path"/* "$_target_dir/data/" 2>/dev/null
    if [ $? -ne 0 ]; then
        log_err "备份失败: 文件复制错误"
        rm -rf "$_target_dir"
        return 1
    fi

    _size="$(get_dir_size "$_target_dir/data")"
    _ts="$(date '+%Y-%m-%d %H:%M:%S')"
    _is_clone="false"

    case "$_src_path" in
        /data/user/*) _is_clone="true" ;;
    esac

    cat > "$_target_dir/meta.json" <<META
{
  "alias": "$_alias",
  "game": "$_game",
  "display": "$_display",
  "pkg": "$_pkg",
  "path": "$_src_path",
  "is_clone": $_is_clone,
  "mode": "$_mode",
  "created_at": "$_ts",
  "data_size": "$_size"
}
META

    log_ok "备份完成: $_alias ($_size)"
    return 0
}

account_list() {
    _game="$1"
    _path_filter="$2"

    _search_dir="$ACCOUNTS_DIR"
    [ -n "$_game" ] && _search_dir="$ACCOUNTS_DIR/$_game"

    _found=""
    for _meta in $(find "$_search_dir" -name meta.json 2>/dev/null); do
        [ -f "$_meta" ] || continue

        _al="$(grep '"alias"' "$_meta" | head -1 | sed 's/.*"alias": *"//;s/".*//')"
        _gn="$(grep '"game"' "$_meta" | head -1 | sed 's/.*"game": *"//;s/".*//')"
        _tm="$(grep '"created_at"' "$_meta" | head -1 | sed 's/.*"created_at": *"//;s/".*//')"
        _sz="$(grep '"data_size"' "$_meta" | head -1 | sed 's/.*"data_size": *"//;s/".*//')"
        _dp="$(grep '"display"' "$_meta" | head -1 | sed 's/.*"display": *"//;s/".*//')"
        _mp="$(grep '"path"' "$_meta" | head -1 | sed 's/.*"path": *"//;s/".*//')"

        [ -n "$_path_filter" ] && [ "$_mp" != "$_path_filter" ] && continue

        [ -n "$_found" ] && _found="$_found,"
        _found="${_found}{\"alias\":\"$_al\",\"game\":\"$_gn\",\"display\":\"$_dp\",\"time\":\"$_tm\",\"size\":\"$_sz\",\"path\":\"$_mp\"}"
    done

    echo "[${_found}]"
}

account_info() {
    _alias="$1"
    _meta="$(find "$ACCOUNTS_DIR" -name meta.json -exec grep -l "\"alias\": *\"$_alias\"" {} \; 2>/dev/null | head -1)"

    if [ -z "$_meta" ] || [ ! -f "$_meta" ]; then
        log_err "账号不存在: $_alias"
        return 1
    fi

    cat "$_meta"
    return 0
}

account_delete() {
    _alias="$1"
    _auto_confirm="$2"

    _meta="$(find "$ACCOUNTS_DIR" -name meta.json -exec grep -l "\"alias\": *\"$_alias\"" {} \; 2>/dev/null | head -1)"

    if [ -z "$_meta" ] || [ ! -f "$_meta" ]; then
        log_err "账号不存在: $_alias"
        return 1
    fi

    if [ "$_auto_confirm" != "1" ]; then
        _gn="$(grep '"game"' "$_meta" | head -1 | sed 's/.*"game": *"//;s/".*//')"
        _dp="$(grep '"display"' "$_meta" | head -1 | sed 's/.*"display": *"//;s/".*//')"
        _tm="$(grep '"created_at"' "$_meta" | head -1 | sed 's/.*"created_at": *"//;s/".*//')"
        echo ""
        log_warn "将删除以下账号:"
        echo "  别名: $_alias"
        echo "  游戏: $_dp"
        echo "  时间: $_tm"
        echo ""
        printf "确认删除? [y/N]: "
        read -r _confirm
        case "$_confirm" in
            [Yy]*) ;;
            *) log_info "已取消"; return 1 ;;
        esac
    fi

    _acct_dir="$(dirname "$_meta")"
    rm -rf "$_acct_dir"
    log_ok "已删除: $_alias"
    return 0
}
