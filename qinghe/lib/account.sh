#!/system/bin/sh
#===============================================================================
# 清荷 - 存号/上号核心逻辑 (CLI 交互模式)
#===============================================================================

. "${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}/lib/common.sh"

get_all_uid() {
    _uid_list=""
    for dir in /data/user/*; do
        [ -d "$dir" ] || continue
        _uid=$(basename "$dir")
        [ "$_uid" -eq "$_uid" ] 2>/dev/null || continue
        _uid_list="$_uid_list $_uid"
    done
    echo "${_uid_list# }"
}

count_backup_files() {
    _src="$1"
    _cnt=0
    for dir in $ACCOUNT_DIRS; do
        [ -d "$_src/$dir" ] || continue
        _cnt=$((_cnt + $(find "$_src/$dir" -type f 2>/dev/null | wc -l)))
    done
    echo $_cnt
}

show_progress() {
    _cur="$1"
    _tot="$2"
    [ $_tot -eq 0 ] && _tot=1
    _pct=$((_cur * 100 / _tot))
    _bar=""
    _i=0
    while [ $_i -lt 10 ]; do
        [ $((_i * 10)) -lt $_pct ] && _bar="${_bar}#" || _bar="${_bar}-"
        _i=$((_i + 1))
    done
    printf "\r  [%s] %d%%" "$_bar" "$_pct"
}

#===============================================================================
# 存号 - 备份五目录到 SD 卡 (交互式, CLI 专用)
#===============================================================================
backup_account() {
    pkg="$1"

    _vlist=""
    for uid in $(get_all_uid); do
        [ -d "/data/user/$uid/$pkg" ] || continue
        _vlist="$_vlist $uid"
    done

    set -- $_vlist
    _total=$#

    if [ $_total -eq 0 ]; then
        warn "未在任何 user 分区找到 $pkg"
        return 1
    fi

    set -- $_vlist
    echo "检测到以下可用分区："
    _i=1
    for uid in "$@"; do
        echo "  $_i. user/$uid"
        _i=$((_i + 1))
    done
    echo "  $_i. 一键批量保存全部"

    echo -n "选择："
    read sel

    if [ "$sel" = "$_i" ]; then
        echo -n "批量备注（留空则无备注）："
        read batch_rm
        echo ""
        for uid in "$@"; do
            do_backup "$uid" "$pkg" "$batch_rm"
        done
        echo ""
        info "全部备份完成"
    else
        idx=$((sel - 1))
        _j=0
        sel_uid=""
        for uid in $(echo $_vlist); do
            [ $_j -eq $idx ] && { sel_uid="$uid"; break; }
            _j=$((_j + 1))
        done
        echo -n "输入备注名（如 大号）："
        read rm
        do_backup "$sel_uid" "$pkg" "$rm"
    fi
}

do_backup() {
    uid="$1"
    pkg="$2"
    remark="$3"

    src="/data/user/$uid/$pkg"

    [ -z "$remark" ] && remark="未命名"
    safe_rm=$(echo "$remark" | sed 's/[ /]/_/g')
    backup_name="${pkg}_${safe_rm}"

    dest="$SAVE_DIR/$uid/$backup_name"

    if [ -d "$dest" ]; then
        if [ "$QH_NO_CONFIRM" = "1" ]; then
            rm -rf "$dest"
        else
            echo -n "备份 [$backup_name] 已存在，覆盖? (y/n): "
            read ow
            [ "$ow" != "y" ] && [ "$ow" != "Y" ] && return
            rm -rf "$dest"
        fi
    fi
    mkdir -p "$dest"

    [ ! -d "$src" ] && { warn "源目录 $src 不存在"; return 1; }

    info "备份 user/$uid -> $backup_name"

    am force-stop "$pkg" 2>/dev/null
    sleep 1

    total=$(count_backup_files "$src")
    [ $total -eq 0 ] && total=1
    current=0
    failed=""

    for dir in $ACCOUNT_DIRS; do
        [ -d "$src/$dir" ] || { warn "目录 $src/$dir 不存在，跳过"; continue; }
        find "$src/$dir" -type f 2>/dev/null | while read f; do
            rel="${f#$src/}"
            mkdir -p "$(dirname "$dest/$rel")" 2>/dev/null
            if cp -a "$f" "$dest/$rel" 2>/dev/null; then
                current=$((current + 1))
            else
                failed="${failed}\n${RED}复制失败: $f${RESET}"
            fi
            [ "$QH_NO_CONFIRM" != "1" ] && show_progress "$current" "$total"
        done
    done
    wait
    [ "$QH_NO_CONFIRM" != "1" ] && echo ""

    [ -n "$failed" ] && echo -e "$failed"

    generate_restore_script "$uid" "$pkg" "$backup_name" "$remark"
    info "备份完成: $dest"
}

generate_restore_script() {
    uid="$1"
    pkg="$2"
    backup_name="$3"
    remark="$4"

    mkdir -p "$SAVE_DIR/restore_scripts" 2>/dev/null
    script_file="$SAVE_DIR/restore_scripts/${backup_name}.sh"
    bak="$SAVE_DIR/$uid/$backup_name"
    src="/data/user/$uid/$pkg"

    cat > "$script_file" << EOF
#!/system/bin/sh
if [ \$(id -u) -ne 0 ]; then
    echo "错误: 需要 root 权限"
    exit 1
fi
PACKAGE="$pkg"
USER_ID="$uid"
SRC="/data/user/$uid/$pkg"
BAK="$bak"
echo "清荷 - 恢复 [$remark] -> user/$uid"
am force-stop "\$PACKAGE" 2>/dev/null
sleep 2
for dir in $ACCOUNT_DIRS; do
    if [ -d "\$BAK/\$dir" ]; then
        rm -rf "\$SRC/\$dir"
        cp -a "\$BAK/\$dir" "\$SRC/\$dir"
    fi
done
chown -R \$(stat -c "%u:%g" "\$SRC" 2>/dev/null) "\$SRC" 2>/dev/null
command -v restorecon >/dev/null 2>&1 && restorecon -R "\$SRC" 2>/dev/null
echo "恢复完成"
EOF

    chmod 755 "$script_file" 2>/dev/null
}

#===============================================================================
# 上号 - 从 SD 卡恢复五目录到游戏 (交互式, CLI 专用)
#===============================================================================
restore_account() {
    pkg="$1"

    _clist=""
    _culist=""
    _crlist=""

    for uid_dir in "$SAVE_DIR"/*; do
        [ -d "$uid_dir" ] || continue
        _uid=$(basename "$uid_dir")
        [ "$_uid" = "restore_scripts" ] && continue
        [ "$_uid" -eq "$_uid" ] 2>/dev/null || continue
        for bak_dir in "$uid_dir"/*; do
            [ -d "$bak_dir" ] || continue
            _bname=$(basename "$bak_dir")
            if echo "$_bname" | grep -q "^${pkg}_"; then
                _remark="${_bname#${pkg}_}"
                _clist="$_clist|$bak_dir"
                _culist="$_culist|$_uid"
                _crlist="$_crlist|$_remark"
            fi
        done
    done

    [ -z "$_clist" ] && { warn "未找到 $pkg 的备份"; return 1; }

    _clist="${_clist#|}"
    _culist="${_culist#|}"
    _crlist="${_crlist#|}"

    echo "匹配到以下备份："
    _pctmp="$_clist"
    _cutmp="$_culist"
    _crtmp="$_crlist"
    _i=1
    while [ -n "$_crtmp" ]; do
        _uid="${_cutmp%%|*}"
        _remark="${_crtmp%%|*}"
        echo "  $_i. [user/$_uid] $_remark"
        _i=$((_i + 1))
        [ "$_crtmp" = "${_crtmp#*|}" ] && break
        _pctmp="${_pctmp#*|}"
        _cutmp="${_cutmp#*|}"
        _crtmp="${_crtmp#*|}"
    done

    echo -n "选择要恢复的序号："
    read sel
    idx=$((sel - 1))

    # find idx-th entry
    _pctmp="$_clist"
    _cutmp="$_culist"
    _crtmp="$_crlist"
    _j=0
    while [ $_j -lt $idx ] && [ -n "$_crtmp" ]; do
        [ "$_crtmp" = "${_crtmp#*|}" ] && break
        _pctmp="${_pctmp#*|}"
        _cutmp="${_cutmp#*|}"
        _crtmp="${_crtmp#*|}"
        _j=$((_j + 1))
    done

    _bak="${_pctmp%%|*}"
    _sel_uid="${_cutmp%%|*}"
    _remark="${_crtmp%%|*}"

    [ -z "$_bak" ] && { warn "选择无效"; return 1; }

    src="/data/user/$_sel_uid/$pkg"
    [ ! -d "$src" ] && { warn "目标目录 $src 不存在，游戏可能未安装"; return 1; }

    info "恢复 [$_sel_uid] $_remark"

    am force-stop "$pkg" 2>/dev/null
    sleep 2

    for dir in $ACCOUNT_DIRS; do
        [ -d "$_bak/$dir" ] || continue
        rm -rf "$src/$dir"
        cp -a "$_bak/$dir" "$src/$dir"
    done

    chown -R $(stat -c "%u:%g" "$src" 2>/dev/null) "$src" 2>/dev/null
    command -v restorecon >/dev/null 2>&1 && restorecon -R "$src" 2>/dev/null

    info "恢复完成"
}

#===============================================================================
# 查看已保存
#===============================================================================
list_accounts() {
    echo "存储位置: $SAVE_DIR"
    echo ""

    if [ ! -d "$SAVE_DIR" ]; then
        echo "(暂无备份)"
        return
    fi

    _total=0
    for uid_dir in "$SAVE_DIR"/*; do
        [ -d "$uid_dir" ] || continue
        _uid=$(basename "$uid_dir")
        [ "$_uid" = "restore_scripts" ] && continue
        [ "$_uid" -eq "$_uid" ] 2>/dev/null || continue
        for bak_dir in "$uid_dir"/*; do
            [ -d "$bak_dir" ] && _total=$((_total+1))
        done
    done

    echo "共 $_total 个备份"
    echo ""

    for uid_dir in "$SAVE_DIR"/*; do
        [ -d "$uid_dir" ] || continue
        _uid=$(basename "$uid_dir")
        [ "$_uid" = "restore_scripts" ] && continue
        [ "$_uid" -eq "$_uid" ] 2>/dev/null || continue
        for bak_dir in "$uid_dir"/*; do
            [ -d "$bak_dir" ] || continue
            _bname=$(basename "$bak_dir")
            echo "  [user/$_uid] $_bname"
        done
    done

    echo ""
    echo "一键恢复脚本: $SAVE_DIR/restore_scripts/"
}
