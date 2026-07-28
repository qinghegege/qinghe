#!/system/bin/sh
#===============================================================================
# 清荷 - 打包脚本
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$SCRIPT_DIR/release"
VERSION="v2.2.6"

mkdir -p "$RELEASE_DIR"

echo "=========================================="
echo "  清荷 - 打包"
echo "  $VERSION"
echo "=========================================="

echo ""
echo "[1/2] 清理旧包..."
rm -f "$RELEASE_DIR"/*.zip 2>/dev/null

echo "[2/2] 生成 Magisk/KSU 模块 zip..."
MODULE_TMP="/tmp/qinghe_mod_build"
rm -rf "$MODULE_TMP" 2>/dev/null
mkdir -p "$MODULE_TMP"

cp "$SCRIPT_DIR/qinghe.sh" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/lib" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/web" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/module/META-INF" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/module.prop" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/customize.sh" "$MODULE_TMP/"
cp "$SCRIPT_DIR/module/action.sh" "$MODULE_TMP/"
cp -r "$SCRIPT_DIR/module/webroot" "$MODULE_TMP/"

chmod -R 755 "$MODULE_TMP"

MODULE_PKG="清荷-module-$VERSION"
cd "$MODULE_TMP"
zip -r "$RELEASE_DIR/$MODULE_PKG.zip" . >/dev/null 2>&1
echo "  -> $RELEASE_DIR/$MODULE_PKG.zip"

rm -rf "$MODULE_TMP" 2>/dev/null

echo ""
echo "打包完成!"
echo "=========================================="
ls -lh "$RELEASE_DIR"/*.zip 2>/dev/null
echo ""
