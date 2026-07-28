#!/system/bin/sh
#===============================================================================
# 清荷 - 腾讯手游账号本地切换器
# 核心逻辑: 存号 = 复制 itop_login.txt 出来, 上号 = 复制回去
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/common.sh"
. "$SCRIPT_DIR/lib/account.sh"

show_help() {
    echo "   清荷 v$QH_VERSION"
    echo ""
    echo "用法: qh [命令]"
    echo ""
    echo "命令:"
    echo "  save <包名>    存号（导出 itop_login.txt）"
    echo "  login <包名>   上号（导入 itop_login.txt）"
    echo "  list           列出已保存的账号"
    echo "  help           显示此帮助"
    echo ""
    echo "无参数启动交互菜单"
}

interactive_menu() {
    while true; do
        mkdir -p "$SAVE_DIR"
        clear
        echo "===================================="
        echo "   清荷 $QH_VERSION"
        echo "   腾讯手游账号本地切换器"
        echo "===================================="
        echo ""
        echo "1. 存号 (导出 itop_login.txt)"
        echo "2. 上号 (导入 itop_login.txt)"
        echo "3. 查看已保存账号"
        echo "4. 退出"
        echo ""
        echo -n "选择: "
        read opt
        case $opt in
            1)
                echo ""
                echo -n "输入游戏包名: "
                read pkg
                [ -z "$pkg" ] && continue
                save_account "$pkg"
                echo ""
                echo "按回车返回..."
                read
                ;;
            2)
                echo ""
                echo -n "输入游戏包名: "
                read pkg
                [ -z "$pkg" ] && continue
                restore_account "$pkg"
                echo ""
                echo "按回车返回..."
                read
                ;;
            3)
                echo ""
                list_accounts
                echo ""
                echo "按回车返回..."
                read
                ;;
            4)
                exit 0
                ;;
        esac
    done
}

require_root

case "${1:-}" in
    save)
        [ -z "$2" ] && die "用法: qh save <包名>"
        save_account "$2"
        ;;
    login)
        [ -z "$2" ] && die "用法: qh login <包名>"
        restore_account "$2"
        ;;
    list)
        list_accounts
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        interactive_menu
        ;;
esac
