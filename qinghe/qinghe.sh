#!/system/bin/sh
#===============================================================================
# 清荷 - 腾讯手游账号本地切换器
# 备份 databases shared_prefs files no_backup app_webview
# 恢复 force-stop -> cp -> chown -> restorecon
#===============================================================================

SCRIPT_DIR="$(cd "${0%/*}" && pwd)"
. "$SCRIPT_DIR/lib/common.sh"
. "$SCRIPT_DIR/lib/account.sh"

show_help() {
    echo "   清荷 v$QH_VERSION"
    echo ""
    echo "用法: qh [命令]"
    echo ""
    echo "命令:"
    echo "  save <包名>    存号（备份五目录）"
    echo "  login <包名>   上号（恢复五目录）"
    echo "  list           查看已保存账号"
    echo "    web <端口>   启动 Web UI (默认端口 8848)
  help           显示此帮助
"
    echo ""
    echo "无参数启动交互菜单"
}

interactive_menu() {
    while true; do
        mkdir -p "$SAVE_DIR"
        clear
        echo ""
        echo -e "${CYAN}====================================${RESET}"
        echo -e "${YELLOW}   清荷 $QH_VERSION${RESET}"
        echo -e "${CYAN}   腾讯手游账号本地切换器${RESET}"
        echo -e "${CYAN}====================================${RESET}"
        echo ""
        echo -e "${GREEN}1. 存号${RESET}   (备份五目录到 SD 卡)"
        echo -e "${GREEN}2. 上号${RESET}   (从 SD 卡恢复五目录)"
        echo -e "${GREEN}3. 查看${RESET}   已保存账号"
        echo -e "${GREEN}4. 退出${RESET}"
        echo ""
        echo -e "${YELLOW}备份内容: databases shared_prefs files no_backup app_webview${RESET}"
        echo -e "${YELLOW}存储位置: $SAVE_DIR${RESET}"
        echo ""
        echo -n "选择: "
        read opt
        case $opt in
            1)
                echo ""
                echo -n "输入游戏包名: "
                read pkg
                [ -z "$pkg" ] && continue
                backup_account "$pkg"
                echo ""
                echo -n "按回车返回..."
                read
                ;;
            2)
                echo ""
                echo -n "输入游戏包名: "
                read pkg
                [ -z "$pkg" ] && continue
                restore_account "$pkg"
                echo ""
                echo -n "按回车返回..."
                read
                ;;
            3)
                echo ""
                list_accounts
                echo ""
                echo -n "按回车返回..."
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
        backup_account "$2"
        ;;
    login)
        [ -z "$2" ] && die "用法: qh login <包名>"
        restore_account "$2"
        ;;
    list)
        list_accounts
        ;;
    web)
        WEB_SCRIPT="$SCRIPT_DIR/web/server.sh"
        if [ -f "$WEB_SCRIPT" ]; then
            sh "$WEB_SCRIPT" "${2:-8848}"
        else
            die "Web 服务脚本未找到: $WEB_SCRIPT"
        fi
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        interactive_menu
        ;;
esac
