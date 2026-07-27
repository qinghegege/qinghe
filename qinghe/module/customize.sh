#!/system/bin/sh
#===============================================================================
# 清荷 - Magisk/KSU 模块安装脚本
#===============================================================================

MODDIR=${MODPATH}
MODID=qinghe

ui_print "====================================="
ui_print "  清荷 - 腾讯手游账号本地切换器"
ui_print "  v1.0.2"
ui_print "====================================="

ui_print "- 创建数据目录..."
mkdir -p /data/$MODID/accounts 2>/dev/null
mkdir -p /data/$MODID/snapshots 2>/dev/null

ui_print "- 设置权限..."
chmod -R 755 $MODDIR 2>/dev/null
chown -R root:root $MODDIR 2>/dev/null

ui_print "- 安装全局命令..."
mkdir -p $MODDIR/system/bin 2>/dev/null
cat > $MODDIR/system/bin/qh << 'QHEOF'
#!/system/bin/sh
exec /data/adb/modules/qinghe/qinghe.sh "$@"
QHEOF
chmod 755 $MODDIR/system/bin/qh 2>/dev/null

ui_print ""
ui_print "安装完成!"
ui_print ""
ui_print "使用方式:"
ui_print "  - 终端输入 qh 启动命令行模式"
ui_print "  - 终端输入 qh web 启动 Web UI"
ui_print "  - 浏览器访问 http://127.0.0.1:8848"
ui_print ""
ui_print "Web UI 120秒无操作自动关闭"
ui_print "====================================="

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/qinghe.sh 0 0 0755
