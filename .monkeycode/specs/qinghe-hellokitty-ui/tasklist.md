# 任务列表 - 清荷 v3 HelloKitty UI

- [ ] 1. 项目结构初始化
  - 创建 `qinghe/` 目录结构 (`lib/`, `web/`, `module/`, `module/webroot/`)
  - 创建项目 `README.md`
  - 更新工作区 `.gitignore`

- [ ] 2. Shell 核心库 `lib/common.sh`
  - 实现 `log_info` / `log_warn` / `log_err` / `log_ok` 日志函数
  - 实现 `check_root` root 权限检测
  - 实现 `detect_env` 运行环境检测
  - 实现 `ensure_data_dirs` 数据目录初始化
  - 实现 `get_data_dir` 数据目录获取 (模块/独立两种模式)
  - 实现 `check_cmd` 依赖命令检查

- [ ] 3. 游戏配置模块 `lib/games.sh`
  - 在脚本中硬编码 5 款游戏配置 (王者荣耀/和平精英/三角洲行动/无畏契约/CF)
  - 实现 `get_game_info` / `get_display_name` / `get_pkg_name` / `get_data_path`
  - 实现 `list_all_games` 列出全部游戏

- [ ] 4. 游戏检测模块 `lib/detect.sh`
  - 实现 `detect_installed_games` 通过 pm 扫描已装游戏, 输出 JSON
  - 实现 `detect_clone_path` 扫描 `/data/user/*/<pkg>` 检测分身路径
  - 实现 `get_dir_size` 获取目录大小
  - 实现 `detect_game_json` 单个游戏完整检测输出

- [ ] 5. 加密模块 `lib/crypto.sh`
  - 实现 `encrypt_file` / `decrypt_file` openssl aes-256-cbc
  - 实现 `tar_encrypt` / `tar_decrypt` tar.gz + 加密组合

- [ ] 6. 账号管理模块 `lib/account.sh`
  - 实现 `account_backup(game, alias, path, mode)` 备份+写 meta.json
  - 实现 `generate_auto_alias` 自动生成备份名
  - 实现 `account_list(game, path)` JSON 列表
  - 实现 `account_info(alias)` 详情
  - 实现 `account_delete(alias, auto_confirm)` 删除

- [ ] 7. 切换引擎 `lib/switch.sh`
  - 实现 `check_game_running(pkg)` 进程检测
  - 实现 `backup_current_snapshot(game, path)` 切换前自动备份
  - 实现 `apply_backup(alias)` 恢复存档到游戏目录
  - 实现 `fix_permissions(path, pkg)` 修复权限和 SELinux
  - 实现 `rollback(game, path)` 回滚
  - 实现 `switch_account(alias)` 一键切换主流程编排

- [ ] 8. 主入口脚本 `qinghe.sh`
  - 加载所有 lib/ 库
  - 实现参数模式路由 (backup/list/delete/switch/detect/web/help)
  - 实现交互菜单模式 (无参数时)
  - 实现 Web 模式 (`qinghe.sh web [port]`)

- [ ] 9. Web 服务 `web/server.sh`
  - 通过 busybox httpd 启动 CGI 服务监听端口 8848
  - 配置 CGI 路径映射 `/cgi-bin/api` → `web/api.sh`
  - 配置静态文件根路径
  - 120 秒无请求自动退出机制

- [ ] 10. Web API `web/api.sh`
  - 实现 detect 端点: 返回含分身信息的游戏列表 JSON
  - 实现 accounts 端点: 返回指定游戏+路径的备份列表 JSON
  - 实现 backup 端点: 执行备份, 支持 mode=auto|custom
  - 实现 restore 端点: 执行恢复 (含自动备份+权限修复)
  - 实现 delete 端点: 删除备份
  - 实现 status 端点: 返回版本/数据目录/SELinux 状态

- [ ] 11. Web UI `web/index.html`
  - 实现 HelloKitty 粉色主题 CSS 变量和基础样式
  - 实现启动加载页: 蝴蝶结动画 + 10秒超时
  - 实现游戏列表页: 自动检测结果 / 超时预置5款回退
  - 实现路径选择页: 本机+分身并排卡片, 选中高亮
  - 实现备份页: 自动备份按钮 + 自定义备份 Modal 输入框
  - 实现恢复页: 备份卡片列表 + 复选框 (单选逻辑) + 确认弹窗 (含详细信息)
  - 实现底部 Web 超时倒计时提示条
  - 实现 Toast 通知组件
  - 所有 API 请求通过 `/cgi-bin/api` CGI 路由

- [ ] 12. KSU/Magisk 模块
  - 创建 `module/module.prop` 模块元数据
  - 实现 `module/customize.sh` 安装脚本
  - 实现 `module/uninstall.sh` 卸载脚本 (询问保留数据)
  - 创建 `module/service.sh` (预留空文件)
  - 将 `web/index.html` 同步到 `module/webroot/index.html`

- [ ] 13. 打包脚本 `package.sh`
  - 生成模块 zip 包 (META-INF + module.prop + 脚本 + Web UI)
  - 生成独立脚本发布包 (qinghe.sh + lib/ + web/ 目录)

- [ ] 14. 全局验证
  - 在 Android 设备上验证模块安装/卸载
  - 验证 Web UI 完整流程 (检测→选游戏→路径→备份→恢复)
  - 验证 10 秒超时回退机制
  - 验证分身路径检测和显示
  - 验证 SELinux Enforcing 环境下的权限修复
