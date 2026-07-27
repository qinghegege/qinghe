#!/system/bin/sh
#===============================================================================
# 清荷 - 游戏检测模块
#===============================================================================

get_dir_size() {
    _path="$1"
    if [ ! -d "$_path" ]; then
        echo "0"
        return
    fi
    du -sh "$_path" 2>/dev/null | cut -f1 || echo "0"
}

detect_clone_path() {
    _pkg="$1"
    _base="/data/data/$_pkg"

    for _udir in /data/user/*/; do
        [ -d "$_udir" ] || continue
        _uid="$(basename "$_udir")"
        [ "$_uid" = "0" ] && continue
        _clone_path="${_udir}$_pkg"
        if [ -d "$_clone_path" ] && [ "$_clone_path" != "$_base" ]; then
            _size="$(get_dir_size "$_clone_path")"
            echo "$_clone_path|$_size"
            return
        fi
    done

    echo ""
}

detect_all_entries() {
    _found=""
    while IFS= read -r _line; do
        [ -z "$_line" ] && continue
        _name="$(echo "$_line" | cut -d'|' -f1)"
        _display="$(echo "$_line" | cut -d'|' -f2)"
        _pkg="$(echo "$_line" | cut -d'|' -f3)"
        _path="$(echo "$_line" | cut -d'|' -f4)"

        _installed=false
        _size="0"
        if [ -d "$_path" ]; then
            _installed=true
            _size="$(get_dir_size "$_path")"
        fi

        _clone_installed=false
        _clone_path=""
        _clone_size="0"
        _clone_result="$(detect_clone_path "$_pkg")"
        if [ -n "$_clone_result" ]; then
            _clone_installed=true
            _clone_path="$(echo "$_clone_result" | cut -d'|' -f1)"
            _clone_size="$(echo "$_clone_result" | cut -d'|' -f2)"
        fi

        [ -n "$_found" ] && _found="$_found,"
        _found="${_found}{\"name\":\"$_name\",\"display\":\"$_display\",\"pkg\":\"$_pkg\""
        _found="${_found},\"installed\":$_installed,\"size\":\"$_size\",\"path\":\"$_path\""
        _found="${_found},\"clone\":{\"installed\":$_clone_installed,\"path\":\"$_clone_path\",\"size\":\"$_clone_size\"}}"
    done <<GAMELIST
$(list_all_games)
GAMELIST

    [ -z "$_found" ] && echo "[]" || echo "[$_found]"
}
