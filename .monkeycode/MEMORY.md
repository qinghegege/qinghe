# 用户指令记忆

本文件记录了用户的指令、偏好和教导，用于在未来的交互中提供参考。

## 格式

### 用户指令条目
用户指令条目应遵循以下格式：

[用户指令摘要]
- Date: [YYYY-MM-DD]
- Context: [提及的场景或时间]
- Instructions:
  - [用户教导或指示的内容，逐行描述]

### 项目知识条目
Agent 在任务执行过程中发现的条目应遵循以下格式：

[项目知识摘要]
- Date: [YYYY-MM-DD]
- Context: Agent 在执行 [具体任务描述] 时发现
- Category: [运维部署|构建方法|测试方法|排错调试|工作流协作|环境配置]
- Instructions:
  - [具体的知识点，逐行描述]

## 去重策略
- 添加新条目前，检查是否存在相似或相同的指令
- 若发现重复，跳过新条目或与已有条目合并
- 合并时，更新上下文或日期信息
- 这有助于避免冗余条目，保持记忆文件整洁

## 条目

### 每次代码更新后自动升版本+推包
- Date: 2026-07-28
- Context: 用户明确要求每次完成代码更新后执行完整发布流程
- Instructions:
  - 修改 `qinghe/lib/common.sh` 中的 `QH_VERSION`
  - 修改 `qinghe/package.sh` 中的 `VERSION`
  - 运行 `sh qinghe/package.sh` 重新构建模块 zip
  - `git add -A && git commit` + `git push origin master`

### Shell 兼容性约束 - 零外部命令依赖
- Date: 2026-07-28
- Context: Agent 排查 Android 设备上 CGI 脚本挂死问题时发现
- Category: 环境配置
- Instructions:
  - 严禁使用 `local` 关键字 (Android mksh 不支持)
  - 严禁使用 `find`/`dirname`/`basename` 外部命令 (busybox 精简版可能不带)
  - `dirname`: 改用 `${var%/*}` 或 `${0%/*}`
  - `basename`: 改用 `${var##*/}`
  - `find`: 改用 `ls` + `[ -d ]` shell 内置
  - 目录遍历: 用 `ls /path/` 替代 glob `for x in /path/*` (防挂载点卡死)
