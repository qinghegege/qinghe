#!/system/bin/sh
#===============================================================================
# 清荷 - KSU/Magisk customize.sh
# KSU 模块安装后执行, Magisk 模块作为备用
#===============================================================================

MODID=qinghe
MODPATH="${MODPATH:-/data/adb/modules/$MODID}"

ui_print "====================================="
ui_print "  清荷 - 腾讯手游账号本地切换器"
ui_print "  v1.1.0"
ui_print "====================================="

ui_print "- 创建数据目录..."
mkdir -p /data/$MODID/accounts 2>/dev/null
mkdir -p /data/$MODID/snapshots 2>/dev/null

ui_print "- 设置权限..."
chmod -R 755 "$MODPATH" 2>/dev/null
chmod 755 "$MODPATH/qinghe.sh" 2>/dev/null

ui_print "安装完成!"
ui_print "  qh       命令行模式"
ui_print "  qh web   启动 Web UI :8848"
ui_print "====================================="
