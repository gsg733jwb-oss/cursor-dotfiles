# 我的 Cursor 多机环境 — 三台机器当作「一台 Cursor」

> 给 Agent 读。聊天历史不能跨机；**约定、规则、配置**通过 Gitee 实时对齐。

## 核心理念

**macOS × 1 + Windows × 2 = 一台逻辑上的 Cursor**

- 三台机器**对等**：均可 pull / push **Gitee**
- 配置改动 → **防抖后自动上传**（约 45 秒）→ 其他机器「开工」pull 即对齐
- Agent 跨机延续：读 `AGENTS.md`、`multi-machine.mdc`，用户可 `@AGENTS.md`

## 云端（仅 Gitee 实时；GitHub 只读镜像）

```
三台机器  ←──pull/push──→  Gitee（主）
                              │
                    每日镜像   ▼
                           GitHub（备份，机器不默认访问）
```

- dotfiles：`https://gitee.com/gsg733jwb/cursor-dotfiles`
- 项目代码：`https://gitee.com/gsg733jwb/jiangwb.git`（各项目独立）

## 同步命令

| 用户说 / 时机 | macOS | Windows |
|---------------|-------|---------|
| **开工** | `cd ~/cursor-dotfiles && ./scripts/cursor-sync.sh pull` | `powershell -File "$env:USERPROFILE\cursor-dotfiles\scripts\cursor-sync.ps1" pull` |
| **收工** / 立即上传 | `./scripts/cursor-sync.sh push` | 同上 `push` |
| 自动上传 | Hook + `cursor-sync-watch`（可选） | Hook + `install-windows-sync.ps1`（可选） |

`push` = 收集本机 → commit → `git pull --rebase gitee` → **只推 Gitee**

## 路径

| dotfiles | macOS | Windows |
|----------|-------|---------|
| `cursor/` | `~/.cursor/` | `%USERPROFILE%\.cursor\` |
| `editor/` | `~/Library/Application Support/Cursor/User/` | `%APPDATA%\Cursor\User\` |

## 平台差异（重要）

| 文件 | macOS | Windows |
|------|-------|---------|
| Hooks 配置 | `cursor/hooks.macos.json` → 本机 `hooks.json` | `cursor/hooks.json`（仅 PowerShell） |
| 自动同步脚本 | `scripts/*.sh` | `scripts/*.ps1` |

**Windows 禁止在 hooks.json 里注册 `.sh`**（会启动 Git Bash 卡住）。

## Agent 行为

- 用户说「开工」→ **直接执行 pull**，不要只告诉用户怎么做
- 用户说「收工」→ **直接执行 push**
- 改了 dotfiles 内规则/脚本 → 提醒可 push，或依赖自动上传
- 默认**不要**访问 GitHub（国内易超时）
- 回复语言：简体中文

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-06-20 | 三机对等；Gitee 实时；AGENTS.md 为跨机共识 |
