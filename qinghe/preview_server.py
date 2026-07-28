#!/usr/bin/env python3
"""清荷 Web UI 预览服务器 - 模拟 busybox httpd CGI API"""
import http.server
import json
import urllib.parse
import os

WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "qinghe", "web")

SAVE_DIR = "/storage/emulated/0/账号存放位置"
VERSION = "v2.2.3"

# ---- mock data ----
MOCK_BACKUPS = [
    {"uid": "0", "name": "com.tencent.tmgp.sgame_大号", "pkg": "com.tencent.tmgp.sgame"},
    {"uid": "0", "name": "com.tencent.tmgp.pubgmhd_小号", "pkg": "com.tencent.tmgp.pubgmhd"},
    {"uid": "10", "name": "com.tencent.tmgp.codev_分身", "pkg": "com.tencent.tmgp.codev"},
]
MOCK_UIDS = ["0", "10", "11"]


class QingheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_GET(self):
        if self.path.startswith("/cgi-bin/api.sh"):
            self.handle_api()
        else:
            super().do_GET()

    def handle_api(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)
        action = params.get("action", [""])[0]

        if action == "status":
            data = {"ok": True, "version": VERSION, "saveDir": SAVE_DIR}
        elif action == "uids":
            pkg = params.get("pkg", [""])[0]
            data = {"ok": True, "uids": MOCK_UIDS}
        elif action == "backup":
            remark = params.get("remark", ["未命名"])[0]
            uid = params.get("uid", ["0"])[0]
            pkg = params.get("pkg", [""])[0]
            data = {"ok": True, "uid": uid, "name": f"{pkg}_{remark}"}
        elif action == "restore":
            data = {"ok": True, "uid": "0", "name": params.get("name", [""])[0]}
        elif action == "list":
            data = {"ok": True, "items": MOCK_BACKUPS}
        else:
            data = {"ok": True, "actions": ["status", "uids", "backup", "restore", "list"]}

        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    with http.server.HTTPServer(("", port), QingheHandler) as httpd:
        print(f"[清荷] 预览服务器: http://0.0.0.0:{port}")
        httpd.serve_forever()
