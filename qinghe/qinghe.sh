#!/system/bin/sh
#===============================================================================
# 清荷 - 腾讯手游账号本地切换器
# 主入口脚本
#
# 用法:
#   sh qinghe.sh                         # 交互式菜单
#   sh qinghe.sh backup <游戏> <别名> [路径] [mode]  # 备份账号
#   sh qinghe.sh list [游戏] [路径]       # 列出账号
#   sh qinghe.sh delete <别名>            # 删除账号
#   sh qinghe.sh switch <别名>            # 切换账号
#   sh qinghe.sh detect                  # 检测游戏 (JSON)
#   sh qinghe.sh web [端口]              # 启动 Web UI
#   sh qinghe.sh help                    # 帮助
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QINGHE_HOME="$SCRIPT_DIR"

. "$QINGHE_HOME/lib/common.sh"
. "$QINGHE_HOME/lib/games.sh"
. "$QINGHE_HOME/lib/detect.sh"
. "$QINGHE_HOME/lib/crypto.sh"
. "$QINGHE_HOME/lib/account.sh"
. "$QINGHE_HOME/lib/switch.sh"

detect_env
check_root
check_dependencies
ensure_data_dirs

show_banner() {
    echo ""
    echo "  ===================================="
    echo "   腾讯手游账号本地切换器"
    echo "   清荷 v1.1.0"
    echo "  ===================================="
    echo ""
}

show_help() {
    show_banner
    echo "用法: sh qinghe.sh <命令> [参数...]"
    echo ""
echo "命令:"
echo "  backup   <游戏> <别名> [路径] [mode]    备份当前游戏数据"
echo "  list     [游戏] [路径]                  列出已备份账号"
echo "  delete   <别名>                         删除账号存档"
echo "  switch   <别名>                         一键切换账号"
echo "  web      [端口]                          启动 Web UI 管理界面"
echo "  help                                    显示此帮助"
    echo ""
    echo "游戏简名:"
    echo "  sgame    王者荣耀"
    echo "  pubgm    和平精英"
    echo "  dfm      三角洲行动"
    echo "  valorant 无畏契约"
    echo "  cf       CF手游"
    echo ""
echo "示例:"
echo "  sh qinghe.sh backup sgame 大号"
echo "  sh qinghe.sh backup sgame 大号 /data/user/10/com.tencent.tmgp.sgame auto"
echo "  sh qinghe.sh switch 大号"
echo "  sh qinghe.sh list"
    echo ""
    echo "无参数运行时进入交互式菜单"
    echo ""
}

show_menu() {
    show_banner
    echo "  请选择操作:"
    echo ""
    echo "  1) 列出已备份账号"
    echo "  2) 备份当前游戏数据"
    echo "  3) 切换账号"
    echo "  4) 删除账号"
    echo "  W) 启动 Web UI (端口 8848)"
    echo "  0) 退出"
    echo ""

    printf "  输入 [0-4/W]: "
    read -r _choice

    case "$_choice" in
        0)
            log_info "再见!"
            exit 0
            ;;
        w|W)
            exec "$QINGHE_HOME/web/server.sh" "${1:-8848}"
            ;;
        1)
            echo ""
            printf "游戏简名 (留空查全部): "
            read -r _g
            printf "数据路径 (留空不限制): "
            read -r _p
            echo ""
            _result="$(account_list "$_g" "$_p")"
            echo "$_result" | sed 's/},{/\n/g' | sed 's/[{[]//g;s/[]}]//g'
            ;;
        2)
            echo ""
            echo "可用游戏:"
            list_all_games | while IFS='|' read -r n d _ _; do
                echo "  $n  $d"
            done
            echo ""
            printf "游戏简名: "
            read -r _gn
            printf "账号别名: "
            read -r _al
            printf "数据路径 (留空自动): "
            read -r _p
            printf "备份模式 (auto/custom, 默认 custom): "
            read -r _md
            [ -z "$_md" ] && _md="custom"
            account_backup "$_gn" "$_al" "$_p" "$_md"
            ;;
        3)
            account_list "" "" 2>/dev/null
            echo ""
            printf "要切换到的账号别名: "
            read -r _al
            switch_account "$_al"
            ;;
        4)
            account_list "" "" 2>/dev/null
            echo ""
            printf "要删除的账号别名: "
            read -r _al
            account_delete "$_al"
            ;;
        *)
            log_err "无效选择"
            ;;
    esac

    echo ""
    echo "---"
    show_menu
}

main() {
    if [ $# -eq 0 ]; then
        show_menu
        exit 0
    fi

    _cmd="$1"
    shift

    case "$_cmd" in
        help|-h|--help)
            show_help
            ;;
        backup)
            account_backup "$1" "$2" "$3" "$4"
            ;;
        list)
            account_list "$1" "$2" | sed 's/},{/\n/g' | sed 's/[{[]//g;s/[]}]//g'
            ;;
        delete|remove)
            account_delete "$1"
            ;;
        switch)
            switch_account "$1"
            ;;
        web)
            exec "$QINGHE_HOME/web/server.sh" "${1:-8848}"
            ;;
        *)
            log_err "未知命令: $_cmd"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
