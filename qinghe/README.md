# 清荷 (Qinghe) - 腾讯手游账号本地切换器

一套运行于 Android 手机端的 Shell 脚本工具，支持 Magisk/KernelSU 模块安装和 MT 管理器直接执行。通过备份和替换游戏本地数据实现多账号快速切换。

## 支持的游戏

| 游戏 | 简名 | 包名 |
|------|------|------|
| 王者荣耀 | sgame | com.tencent.tmgp.sgame |
| 和平精英 | pubgm | com.tencent.tmgp.pubgmhd |
| 三角洲行动 | dfm | com.tencent.tmgp.dfm |
| 无畏契约 | valorant | com.tencent.tmgp.valorant |
| CF手游 | cf | com.tencent.tmgp.cf |

## 使用方式

### MT 管理器

1. 将 `清荷/` 目录复制到手机
2. 点击 `qinghe.sh`，选择「执行」
3. 按菜单提示操作

### 命令行

```sh
# 检测已安装的腾讯手游
sh qinghe.sh detect

# 备份当前游戏数据
sh qinghe.sh backup sgame 大号

# 列出已备份账号
sh qinghe.sh list

# 切换账号
sh qinghe.sh switch 大号

# 启动 Web UI (端口 8848)
sh qinghe.sh web
```

### Magisk/KSU 模块

1. 将 `清荷-module-v1.0.0.zip` 通过 Magisk Manager 或 KSU WebUI 刷入
2. 重启或手动加载模块
3. 终端输入 `qh` 使用命令行
4. 终端输入 `qh web` 启动 Web UI
5. 浏览器访问 `http://127.0.0.1:8848`

## 功能

- 自动检测手机已安装的腾讯手游
- 支持本机路径和分身路径（自动识别双开/分身空间）
- 自动备份（时间戳命名）和自定义命名备份
- 框选式恢复界面，含自动备份确认
- Web UI HelloKitty 粉色主题
- 120秒无操作自动关闭 Web 服务
- 切换前自动备份当前数据，支持失败回滚
- 加密备份（需 openssl）

## 依赖

| 命令 | 用途 | 必需 |
|------|------|------|
| sh | 脚本解释器 | 必需 |
| cp / mv / rm | 文件操作 | 必需 |
| tar / gzip | 打包压缩 | 必需 |
| openssl | 加密解密 | 可选 |
| pgrep | 进程检测 | 推荐 |
| pm | 包管理器 | 推荐 |
| busybox httpd | Web 服务 | 推荐 |

## 版本

v1.0.0 - 初始版本
