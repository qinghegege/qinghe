#!/system/bin/sh
#===============================================================================
# 清荷 - 存号/上号核心逻辑
#===============================================================================

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

do_save() {
    local uid="$1"
    local pkg="$2"
    local remark="$3"

    mkdir -p "$SAVE_DIR/$uid"
    local src="/data/user/$uid/$pkg/files/itop_login.txt"
    local dst
    if [ -n "$remark" ]; then
        dst="$SAVE_DIR/$uid/${remark}_${pkg}_itop_login.txt"
    else
        dst="$SAVE_DIR/$uid/${pkg}_itop_login.txt"
    fi

    if [ ! -f "$src" ]; then
        echo "失败: 文件不存在 $src"
        return 1
    fi

    cp "$src" "$dst"
    echo "保存完成: user/$uid -> $dst"
}

save_account() {
    local pkg="$1"

    local valid_uids=()
    local all_uids=($(get_all_uid))
    for uid in "${all_uids[@]}"; do
        if [ -f "/data/user/$uid/$pkg/files/itop_login.txt" ]; then
            valid_uids+=("$uid")
        fi
    done

    if [ ${#valid_uids[@]} -eq 0 ]; then
        echo "未在任何 user 分区找到该游戏的登录文件!"
        return 1
    fi

    echo "检测到以下可用账号分区："
    local i=1
    for uid in "${valid_uids[@]}"; do
        echo "  $i. user/$uid"
        i=$((i+1))
    done
    echo "  $i. 一键批量保存全部"

    echo -n "请选择序号："
    read sel

    if [ "$sel" = "$i" ]; then
        echo -n "批量备注（留空则无备注）："
        read batch_rm
        echo ""
        for uid in "${valid_uids[@]}"; do
            do_save "$uid" "$pkg" "$batch_rm"
        done
        echo "全部账号批量保存完毕"
    else
        local idx=$((sel - 1))
        local uid="${valid_uids[$idx]}"

        echo "1. 无备注"
        echo "2. 自定义备注"
        echo -n "选择："
        read opt
        local rm=""
        if [ "$opt" = "2" ]; then
            echo -n "输入备注："
            read rm
        fi
        do_save "$uid" "$pkg" "$rm"
    fi
}

restore_account() {
    local pkg="$1"

    local files=()
    local file_uids=()
    for subdir in "$SAVE_DIR"/*; do
        [ -d "$subdir" ] || continue
        local uid=$(basename "$subdir")
        if [ "$uid" -eq "$uid" ] 2>/dev/null; then
            for f in "$subdir"/*; do
                [ -f "$f" ] || continue
                local fname=$(basename "$f")
                if echo "$fname" | grep -q "$pkg"; then
                    files+=("$fname")
                    file_uids+=("$uid")
                fi
            done
        fi
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo "未找到包含 $pkg 的账号文件!"
        return 1
    fi

    echo "匹配到以下账号文件："
    local i=1
    for idx in "${!files[@]}"; do
        echo "  $((i)). [user/${file_uids[$idx]}] ${files[$idx]}"
        i=$((i+1))
    done

    echo -n "选择要使用的文件序号："
    read sel
    local idx=$((sel - 1))
    local file_name="${files[$idx]}"
    local target_uid="${file_uids[$idx]}"
    local src="$SAVE_DIR/$target_uid/$file_name"

    local dest_dir="/data/user/$target_uid/$pkg/files"
    local dest_file="$dest_dir/itop_login.txt"

    mkdir -p "$dest_dir"

    if [ -f "$dest_file" ]; then
        echo "目标目录已存在 itop_login.txt"
        echo "1. 覆盖导入"
        echo "2. 取消"
        echo -n "选择："
        read opt
        if [ "$opt" != "1" ]; then
            echo "已取消"
            return 0
        fi
        rm -f "$dest_file"
    fi

    cp "$src" "$dest_file"
    chmod 777 "$dest_file"
    echo "上号完成: $src -> /data/user/$target_uid/$pkg/files/"
}

list_accounts() {
    echo "存储位置: $SAVE_DIR"
    echo ""
    if [ ! -d "$SAVE_DIR" ]; then
        echo "(暂无保存的账号)"
        return
    fi

    local count=0
    for subdir in "$SAVE_DIR"/*; do
        [ -d "$subdir" ] || continue
        local uid=$(basename "$subdir")
        echo "--- user/$uid ---"
        for f in "$subdir"/*; do
            [ -f "$f" ] || continue
            echo "  $(basename "$f")"
            count=$((count+1))
        done
        echo ""
    done
    echo "共 $count 个账号"
}
