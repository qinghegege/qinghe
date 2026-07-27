#!/system/bin/sh
#===============================================================================
# 清荷 - 游戏配置
# 5款核心腾讯手游, 配置硬编码无外部依赖
#===============================================================================

get_game_info() {
    _name="$1"
    case "$_name" in
        sgame)    echo "sgame|王者荣耀|com.tencent.tmgp.sgame|/data/data/com.tencent.tmgp.sgame" ;;
        pubgm)    echo "pubgm|和平精英|com.tencent.tmgp.pubgmhd|/data/data/com.tencent.tmgp.pubgmhd" ;;
        dfm)      echo "dfm|三角洲行动|com.tencent.tmgp.dfm|/data/data/com.tencent.tmgp.dfm" ;;
        valorant) echo "valorant|无畏契约|com.tencent.tmgp.valorant|/data/data/com.tencent.tmgp.valorant" ;;
        cf)       echo "cf|CF手游|com.tencent.tmgp.cf|/data/data/com.tencent.tmgp.cf" ;;
        *)        return 1 ;;
    esac
}

get_display_name() {
    _name="$1"
    _info="$(get_game_info "$_name")" || { echo "未知游戏"; return 1; }
    echo "$_info" | cut -d'|' -f2
}

get_pkg_name() {
    _name="$1"
    _info="$(get_game_info "$_name")" || { echo ""; return 1; }
    echo "$_info" | cut -d'|' -f3
}

get_data_path() {
    _name="$1"
    _info="$(get_game_info "$_name")" || { echo ""; return 1; }
    echo "$_info" | cut -d'|' -f4
}

list_all_games() {
    echo "sgame|王者荣耀|com.tencent.tmgp.sgame|/data/data/com.tencent.tmgp.sgame"
    echo "pubgm|和平精英|com.tencent.tmgp.pubgmhd|/data/data/com.tencent.tmgp.pubgmhd"
    echo "dfm|三角洲行动|com.tencent.tmgp.dfm|/data/data/com.tencent.tmgp.dfm"
    echo "valorant|无畏契约|com.tencent.tmgp.valorant|/data/data/com.tencent.tmgp.valorant"
    echo "cf|CF手游|com.tencent.tmgp.cf|/data/data/com.tencent.tmgp.cf"
}

is_valid_game() {
    _name="$1"
    get_game_info "$_name" >/dev/null 2>&1
}
