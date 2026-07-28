#!/system/bin/sh
#===============================================================================
# 清荷 - CGI 连通性探针 (放在 web/cgi-bin/ping.sh)
#===============================================================================

echo "Content-Type: application/json"
echo ""
echo "{\"ok\":true,\"alive\":true,\"ts\":$(date +%s),\"whoami\":\"$(id -un 2>/dev/null || echo unknown)\"}"