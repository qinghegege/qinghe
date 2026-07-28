#!/system/bin/sh
#===============================================================================
# 清荷 - CGI API (busybox httpd)
#===============================================================================

WEB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODULE_DIR="$(cd "$WEB_DIR/.." && pwd)"
SCRIPT_DIR="$MODULE_DIR"
. "$MODULE_DIR/lib/common.sh"

echo "Content-Type: application/json"
echo ""

json_ok() { echo "{\"ok\":true${1:+,$1}}"; }
json_err() { echo "{\"ok\":false,\"error\":\"$1\"}"; }

get_param() {
    _key="$1"
    for _pair in $(echo "$QUERY_STRING" | tr '&' ' '); do
        _k="${_pair%%=*}"
        [ "$_k" = "$_key" ] && { echo "${_pair#*=}"; return 0; }
    done
}

url_decode() {
    _s="$1"
    _s=$(echo "$_s" | sed 's/+/ /g; s/%\([0-9A-F][0-9A-F]\)/\\x\1/gI')
    printf '%b' "$_s" 2>/dev/null || echo "$_s"
}

action=$(get_param "action")

case "$action" in
    status)
        json_ok "\"version\":\"$QH_VERSION\",\"saveDir\":\"$SAVE_DIR\""
        ;;

    uids)
        pkg=$(get_param "pkg")
        [ -z "$pkg" ] && { json_err "缺少 pkg 参数"; exit 0; }

        uids=""

        # 逐个探测已知路径 (纯 shell builtin，完全不用 find/dirname/basename)
        [ -d "/data/data/$pkg" ] && uids="$uids\"0\","
        [ -d "/data/user_de/0/$pkg" ] && { echo "|$uids|" | grep -q '"0"' || uids="$uids\"0\","; }

        # ls 列出多用户分区再逐个 stat (独立进程，不卡挂载点)
        for _u in $(ls /data/user/ 2>/dev/null); do
            [ "$_u" -eq "$_u" ] 2>/dev/null || continue
            [ "$_u" = "0" ] && continue
            [ -d "/data/user/$_u/$pkg" ] || continue
            uids="$uids\"$_u\","
        done

        json_ok "\"uids\":[${uids%,}]"
        ;;

    backup)
        pkg=$(get_param "pkg")
        uid=$(get_param "uid")
        remark=$(get_param "remark")
        [ -z "$pkg" ] && { json_err "缺少 pkg 参数"; exit 0; }
        [ -z "$uid" ] && uid="0"
        [ -z "$remark" ] && remark="未命名"

        remark=$(url_decode "$remark")
        pkg=$(url_decode "$pkg")

        safe_rm=$(echo "$remark" | sed 's/[ /]/_/g')
        backup_name="${pkg}_${safe_rm}"

        if [ "$uid" = "0" ]; then
            src="/data/data/$pkg"
        else
            src="/data/user/$uid/$pkg"
        fi
        dest="$SAVE_DIR/$uid/$backup_name"

        if [ ! -d "$src" ]; then
            json_err "游戏目录不存在: $src"
            exit 0
        fi

        rm -rf "$dest" 2>/dev/null
        mkdir -p "$dest" 2>/dev/null

        am force-stop "$pkg" 2>/dev/null
        sleep 1

        found=0
        for dir in $ACCOUNT_DIRS; do
            if [ -d "$src/$dir" ]; then
                cp -a "$src/$dir" "$dest/" 2>/dev/null
                found=1
            fi
        done

        if [ $found -eq 0 ]; then
            json_err "无账号数据可备份"
            exit 0
        fi

        mkdir -p "$SAVE_DIR/restore_scripts" 2>/dev/null
        script_file="$SAVE_DIR/restore_scripts/${backup_name}.sh"
        cat > "$script_file" << EOF
#!/system/bin/sh
if [ \$(id -u) -ne 0 ]; then
    echo "错误: 需要 root 权限"
    exit 1
fi
PACKAGE="$pkg"
USER_ID="$uid"
if [ "$uid" = "0" ]; then
    SRC="/data/data/$pkg"
else
    SRC="/data/user/$uid/$pkg"
fi
BAK="$SAVE_DIR/$uid/$backup_name"
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

        json_ok "\"uid\":\"$uid\",\"name\":\"$backup_name\""
        ;;

    restore)
        pkg=$(get_param "pkg")
        uid=$(get_param "uid")
        name=$(get_param "name")
        [ -z "$pkg" ] && { json_err "缺少 pkg 参数"; exit 0; }
        [ -z "$uid" ] && uid="0"
        [ -z "$name" ] && { json_err "缺少 name 参数"; exit 0; }

        pkg=$(url_decode "$pkg")
        uid=$(url_decode "$uid")
        name=$(url_decode "$name")

        if [ "$uid" = "0" ]; then
            src="/data/data/$pkg"
        else
            src="/data/user/$uid/$pkg"
        fi
        bak="$SAVE_DIR/$uid/$name"

        if [ ! -d "$bak" ]; then
            json_err "备份不存在: $name"
            exit 0
        fi

        if [ ! -d "$src" ]; then
            json_err "游戏目录不存在: $src"
            exit 0
        fi

        am force-stop "$pkg" 2>/dev/null
        sleep 2

        for dir in $ACCOUNT_DIRS; do
            if [ -d "$bak/$dir" ]; then
                rm -rf "$src/$dir"
                cp -a "$bak/$dir" "$src"/
            fi
        done

        chown -R $(stat -c "%u:%g" "$src" 2>/dev/null) "$src" 2>/dev/null
        command -v restorecon >/dev/null 2>&1 && restorecon -R "$src" 2>/dev/null

        json_ok "\"uid\":\"$uid\",\"name\":\"$name\""
        ;;

    list)
        items=""
        if [ -d "$SAVE_DIR" ]; then
            for uid_dir in "$SAVE_DIR"/*; do
                [ -d "$uid_dir" ] || continue
                _uid=$(basename "$uid_dir")
                [ "$_uid" = "restore_scripts" ] && continue
                [ "$_uid" -eq "$_uid" ] 2>/dev/null || continue
                for bak_dir in "$uid_dir"/*; do
                    [ -d "$bak_dir" ] || continue
                    _bname=$(basename "$bak_dir")
                    _pkg="${_bname%%_*}"
                    items="$items{\"uid\":\"$_uid\",\"name\":\"$_bname\",\"pkg\":\"$_pkg\"},"
                done
            done
        fi
        json_ok "\"items\":[${items%,}]"
        ;;

    *)
        json_ok "\"actions\":[\"status\",\"uids\",\"backup\",\"restore\",\"list\"]"
        ;;
esac

exit 0
