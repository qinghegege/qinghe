#!/system/bin/sh
#===============================================================================
# 清荷 - CGI API
# busybox httpd: 所有参数通过 QUERY_STRING 传入 (GET)
#===============================================================================

WEB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODULE_DIR="$(cd "$WEB_DIR/.." && pwd)"
SCRIPT_DIR="$MODULE_DIR"
. "$MODULE_DIR/lib/common.sh"
. "$MODULE_DIR/lib/account.sh"

echo "Content-Type: application/json"
echo ""

json_ok() {
    local data="$1"
    echo "{\"ok\":true${data:+,$data}}"
}

json_err() {
    local msg="$1"
    echo "{\"ok\":false,\"error\":\"$msg\"}"
}

get_param() {
    local key="$1"
    echo "$QUERY_STRING" | tr '&' '\n' | while IFS='=' read -r k v; do
        if [ "$k" = "$key" ]; then
            printf '%s' "$v"
        fi
    done
}

url_decode() {
    echo "$1" | sed 's/+/ /g;s/%\([0-9a-fA-F][0-9a-fA-F]\)/\\x\1/g' | xargs -0 printf '%b' 2>/dev/null || echo "$1"
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
        for uid in $(get_all_uid); do
            if [ -d "/data/user/$uid/$pkg" ]; then
                uids="$uids\"$uid\","
            fi
        done
        uids="[${uids%,}]"
        json_ok "\"uids\":$uids"
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

        do_backup "$uid" "$pkg" "$remark" 2>&1
        json_ok "\"msg\":\"backup done\",\"uid\":\"$uid\",\"pkg\":\"$pkg\""
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

        src="/data/user/$uid/$pkg"
        bak="$SAVE_DIR/$uid/$name"

        if [ ! -d "$bak" ]; then
            json_err "备份 $name 不存在"
            exit 0
        fi

        am force-stop "$pkg" 2>/dev/null
        sleep 2

        for dir in $ACCOUNT_DIRS; do
            if [ -d "$bak/$dir" ]; then
                rm -rf "$src/$dir"
                cp -a "$bak/$dir" "$src/$dir"
            fi
        done

        chown -R $(stat -c "%u:%g" "$src" 2>/dev/null) "$src" 2>/dev/null
        command -v restorecon >/dev/null 2>&1 && restorecon -R "$src" 2>/dev/null

        json_ok "\"msg\":\"restore done\",\"uid\":\"$uid\",\"pkg\":\"$pkg\""
        ;;

    list)
        items=""
        if [ -d "$SAVE_DIR" ]; then
            for uid_dir in "$SAVE_DIR"/*; do
                [ -d "$uid_dir" ] || continue
                local uid=$(basename "$uid_dir")
                if [ "$uid" = "restore_scripts" ]; then continue; fi
                if [ "$uid" -eq "$uid" ] 2>/dev/null; then
                    for bak_dir in "$uid_dir"/*; do
                        [ -d "$bak_dir" ] || continue
                        local bname=$(basename "$bak_dir")
                        items="$items{\"uid\":\"$uid\",\"name\":\"$bname\"},"
                    done
                fi
            done
        fi
        items="[${items%,}]"
        json_ok "\"items\":$items"
        ;;

    *)
        json_ok "\"actions\":[\"status\",\"uids\",\"backup\",\"restore\",\"list\"]"
        ;;
esac

exit 0
