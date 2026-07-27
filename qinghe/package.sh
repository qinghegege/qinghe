#!/system/bin/sh
#===============================================================================
# 清荷 - 打包脚本
# 生成 Magisk/KSU 模块 zip 和 MT 管理器脚本发布包
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$SCRIPT_DIR/release"
VERSION="v1.0.2"

mkdir -p "$RELEASE_DIR"

echo "=========================================="
echo "  清荷 - 打包"
echo "  $VERSION"
echo "=========================================="

echo ""
echo "[1/3] 清理旧包..."
rm -f "$RELEASE_DIR"/*.zip 2>/dev/null

echo "[2/3] 生成 Magisk/KSU 模块 zip..."
MODULE_TMP="/tmp/qinghe_mod_build"
rm -rf "$MODULE_TMP" 2>/dev/null
mkdir -p "$MODULE_TMP"

cp "$SCRIPT_DIR/qinghe.sh" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/lib" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/web" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/module/META-INF" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/module.prop" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/customize.sh" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/uninstall.sh" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/service.sh" "$MODULE_TMP/"

mkdir -p "$MODULE_TMP/webroot"
cp "$SCRIPT_DIR/web/index.html" "$MODULE_TMP/webroot/"

chmod -R 755 "$MODULE_TMP"

MODULE_PKG="清荷-module-$VERSION"
cd "$MODULE_TMP"
zip -r "$RELEASE_DIR/$MODULE_PKG.zip" . >/dev/null 2>&1
echo "  -> $RELEASE_DIR/$MODULE_PKG.zip"

echo "[3/3] 生成独立脚本包..."
SCRIPT_TMP="/tmp/qinghe_scr_build"
rm -rf "$SCRIPT_TMP" 2>/dev/null
mkdir -p "$SCRIPT_TMP/清荷"

cp "$SCRIPT_DIR/qinghe.sh" "$SCRIPT_TMP/清荷/"
cp -r "$SCRIPT_DIR/lib" "$SCRIPT_TMP/清荷/"
cp -r "$SCRIPT_DIR/web" "$SCRIPT_TMP/清荷/"

SCRIPT_PKG="清荷-script-$VERSION"
cd "$SCRIPT_TMP"
zip -r "$RELEASE_DIR/$SCRIPT_PKG.zip" "清荷/" >/dev/null 2>&1
echo "  -> $RELEASE_DIR/$SCRIPT_PKG.zip"

rm -rf "$MODULE_TMP" "$SCRIPT_TMP" 2>/dev/null

echo ""
echo "打包完成!"
echo "=========================================="
ls -lh "$RELEASE_DIR"/*.zip 2>/dev/null
echo ""
