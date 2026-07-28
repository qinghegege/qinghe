#!/system/bin/sh
#===============================================================================
# 清荷 - KSU/Magisk customize.sh
#===============================================================================

MODID=qinghe
MODPATH="${MODPATH:-/data/adb/modules/$MODID}"

ui_print "====================================="
ui_print "  清荷 - 腾讯手游账号本地切换器"
ui_print "  v2.2.3"
ui_print "====================================="

ui_print "- 创建数据目录..."
mkdir -p /data/$MODID 2>/dev/null

ui_print "- 设置权限..."
chmod -R 755 "$MODPATH" 2>/dev/null
chmod 755 "$MODPATH/qinghe.sh" 2>/dev/null

ui_print "- 安装全局命令..."
mkdir -p "$MODPATH/system/bin" 2>/dev/null
cat > "$MODPATH/system/bin/qh" << 'QHEOF'
#!/system/bin/sh
exec /data/adb/modules/qinghe/qinghe.sh "$@"
QHEOF
chmod 755 "$MODPATH/system/bin/qh" 2>/dev/null

ui_print ""
ui_print "安装完成!"
ui_print "  KSU: 点击模块操作按钮一键启动"
ui_print "  qh save <包名>   存号"
ui_print "  qh login <包名>  上号"
ui_print "  qh web [端口]    启动 Web UI"
ui_print "  qh list          查看已保存"
ui_print "  qh               交互菜单"
ui_print "====================================="
