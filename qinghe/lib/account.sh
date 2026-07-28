#!/system/bin/sh
#===============================================================================
# 清荷 - 存号/上号核心逻辑
# 备份: databases shared_prefs files no_backup app_webview
# 恢复: force-stop -> rm -> cp -> chown -R -> restorecon -R
#===============================================================================

. "$SCRIPT_DIR/lib/common.sh"

get_all_uid() {
    local uid_list=()
    for dir in /data/user/*; do
        local uid=$(basename "$dir")
        if [ "$uid" -eq "$uid" ] 2>/dev/null; then
            uid_list+=("$uid")
        fi
    done
    echo "${uid_list[@]}"
}

count_backup_files() {
    local src="$1"
    local count=0
    for dir in $ACCOUNT_DIRS; do
        if [ -d "$src/$dir" ]; then
            count=$((count + $(find "$src/$dir" -type f 2>/dev/null | wc -l)))
        fi
    done
    echo $count
}

show_progress() {
    local current="$1" total="$2"
    local pct=$((current * 100 / (total > 0 ? total : 1)))
    local bar=""
    local i=0
    while [ $i -lt 10 ]; do
        [ $((i * 10)) -lt $pct ] && bar="${bar}#" || bar="${bar}-"
        i=$((i + 1))
    done
    printf "\r  [%s] %d%%" "$bar" "$pct"
}

#===============================================================================
# 存号 - 备份五目录到 SD 卡
#===============================================================================
backup_account() {
    local pkg="$1"

    local valid_uids=()
    local all_uids=($(get_all_uid))
    for uid in "${all_uids[@]}"; do
        if [ -d "/data/user/$uid/$pkg" ]; then
            valid_uids+=("$uid")
        fi
    done

    if [ ${#valid_uids[@]} -eq 0 ]; then
        warn "未在任何 user 分区找到 $pkg"
        return 1
    fi

    echo "检测到以下可用分区："
    local i=1
    for uid in "${valid_uids[@]}"; do
        echo "  $i. user/$uid"
        i=$((i+1))
    done
    echo "  $i. 一键批量保存全部"

    echo -n "选择："
    read sel

    if [ "$sel" = "$i" ]; then
        echo -n "批量备注（留空则无备注）："
        read batch_rm
        echo ""
        for uid in "${valid_uids[@]}"; do
            do_backup "$uid" "$pkg" "$batch_rm"
        done
        echo ""
        info "全部备份完成"
    else
        local idx=$((sel - 1))
        local uid="${valid_uids[$idx]}"
        echo -n "输入备注名（如 大号）："
        read rm
        do_backup "$uid" "$pkg" "$rm"
    fi
}

do_backup() {
    local uid="$1"
    local pkg="$2"
    local remark="$3"

    local src="/data/user/$uid/$pkg"

    [ -z "$remark" ] && remark="未命名"
    local safe_rm=$(echo "$remark" | tr ' /' '__')
    local backup_name="${pkg}_${safe_rm}"

    local dest="$SAVE_DIR/$uid/$backup_name"

    if [ -d "$dest" ]; then
        echo -n "备份 [$backup_name] 已存在，覆盖? (y/n): "
        read ow
        [ "$ow" != "y" ] && [ "$ow" != "Y" ] && return
        rm -rf "$dest"
    fi
    mkdir -p "$dest"

    if [ ! -d "$src" ]; then
        warn "源目录 $src 不存在"
        return 1
    fi

    info "备份 user/$uid -> $backup_name"

    am force-stop "$pkg" 2>/dev/null
    sleep 1

    local total=$(count_backup_files "$src")
    [ $total -eq 0 ] && total=1
    local current=0
    local failed=""

    for dir in $ACCOUNT_DIRS; do
        if [ -d "$src/$dir" ]; then
            find "$src/$dir" -type f 2>/dev/null | while read f; do
                local rel="${f#$src/}"
                mkdir -p "$(dirname "$dest/$rel")" 2>/dev/null
                if cp -a "$f" "$dest/$rel" 2>/dev/null; then
                    current=$((current + 1))
                else
                    failed="${failed}\n${RED}复制失败: $f${RESET}"
                fi
                show_progress "$current" "$total"
            done
        else
            warn "目录 $src/$dir 不存在，跳过"
        fi
    done
    wait
    echo ""

    if [ -n "$failed" ]; then
        echo -e "$failed"
    fi

    generate_restore_script "$uid" "$pkg" "$backup_name" "$remark"
    info "备份完成: $dest"
}

generate_restore_script() {
    local uid="$1"
    local pkg="$2"
    local backup_name="$3"
    local remark="$4"

    mkdir -p "$SAVE_DIR/restore_scripts"

    local script_file="$SAVE_DIR/restore_scripts/${backup_name}.sh"
    local src="/data/user/$uid/$pkg"
    local bak="$SAVE_DIR/$uid/$backup_name"

    cat > "$script_file" << EOF
#!/system/bin/sh
#===============================================================================
# 清荷恢复脚本 - ${remark} -> user/${uid}
# 包名: ${pkg}
# 备份: ${backup_name}
# 生成时间: $(date '+%Y-%m-%d %H:%M')
#===============================================================================
if [ \$(id -u) -ne 0 ]; then
    echo "错误: 需要 root 权限"
    exit 1
fi

PACKAGE="${pkg}"
USER_ID="${uid}"
SRC="/data/user/${uid}/${pkg}"
BAK="${bak}"

echo "清荷 - 正在恢复账号 [${remark}] -> user/${uid}"

am force-stop "\$PACKAGE" 2>/dev/null
sleep 2

for dir in ${ACCOUNT_DIRS}; do
    if [ -d "\$BAK/\$dir" ]; then
        rm -rf "\$SRC/\$dir"
        cp -a "\$BAK/\$dir" "\$SRC/\$dir"
    fi
done

chown -R \$(stat -c "%u:%g" "\$SRC" 2>/dev/null) "\$SRC" 2>/dev/null

if command -v restorecon >/dev/null 2>&1; then
    restorecon -R "\$SRC" 2>/dev/null
fi

echo "恢复完成"
EOF

    chmod 755 "$script_file"
}

#===============================================================================
# 上号 - 从 SD 卡恢复五目录到游戏
#===============================================================================
restore_account() {
    local pkg="$1"

    local candidates=()
    local cand_uids=()
    local cand_remarks=()

    for uid_dir in "$SAVE_DIR"/*; do
        [ -d "$uid_dir" ] || continue
        local uid=$(basename "$uid_dir")
        if [ "$uid" != "restore_scripts" ] && [ "$uid" -eq "$uid" ] 2>/dev/null; then
            for bak_dir in "$uid_dir"/*; do
                [ -d "$bak_dir" ] || continue
                local bname=$(basename "$bak_dir")
                if echo "$bname" | grep -q "^${pkg}_"; then
                    local remark="${bname#${pkg}_}"
                    candidates+=("$bak_dir")
                    cand_uids+=("$uid")
                    cand_remarks+=("$remark")
                fi
            done
        fi
    done

    if [ ${#candidates[@]} -eq 0 ]; then
        warn "未找到 $pkg 的备份"
        return 1
    fi

    echo "匹配到以下备份："
    local i=1
    for idx in "${!candidates[@]}"; do
        echo "  $((i)). [user/${cand_uids[$idx]}] ${cand_remarks[$idx]}"
        i=$((i+1))
    done

    echo -n "选择要恢复的序号："
    read sel
    local idx=$((sel - 1))
    local dest_uid="${cand_uids[$idx]}"
    local bak_path="${candidates[$idx]}"
    local src="/data/user/$dest_uid/$pkg"

    if [ ! -d "$src" ]; then
        warn "目标目录 $src 不存在，游戏可能未安装"
        return 1
    fi

    info "恢复 [$dest_uid] ${cand_remarks[$idx]}"

    am force-stop "$pkg" 2>/dev/null
    sleep 2

    for dir in $ACCOUNT_DIRS; do
        if [ -d "$bak_path/$dir" ]; then
            rm -rf "$src/$dir"
            cp -a "$bak_path/$dir" "$src/$dir"
        fi
    done

    chown -R $(stat -c "%u:%g" "$src" 2>/dev/null) "$src" 2>/dev/null

    if command -v restorecon >/dev/null 2>&1; then
        restorecon -R "$src" 2>/dev/null
    fi

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

    local total=0
    for uid_dir in "$SAVE_DIR"/*; do
        [ -d "$uid_dir" ] || continue
        local uid=$(basename "$uid_dir")
        if [ "$uid" = "restore_scripts" ]; then continue; fi
        if [ "$uid" -eq "$uid" ] 2>/dev/null; then
            for bak_dir in "$uid_dir"/*; do
                [ -d "$bak_dir" ] && total=$((total+1))
            done
        fi
    done

    echo "共 $total 个备份"
    echo ""

    for uid_dir in "$SAVE_DIR"/*; do
        [ -d "$uid_dir" ] || continue
        local uid=$(basename "$uid_dir")
        if [ "$uid" = "restore_scripts" ]; then continue; fi
        if [ "$uid" -eq "$uid" ] 2>/dev/null; then
            for bak_dir in "$uid_dir"/*; do
                [ -d "$bak_dir" ] || continue
                local bname=$(basename "$bak_dir")
                echo "  [user/$uid] $bname"
            done
        fi
    done

    echo ""
    echo "一键恢复脚本: $SAVE_DIR/restore_scripts/"
}
