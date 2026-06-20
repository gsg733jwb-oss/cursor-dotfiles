# 我的 Cursor 多机环境

> 给 Agent 读的环境说明。聊天历史不能跨机同步；以本文件 + `cursor/rules/multi-machine.mdc` 为准。

## 机器角色（对等）

| 机器 | 权限 |
|------|------|
| **macOS × 1** | 仅对 **Gitee** pull / push |
| **Windows × 2** | 仅对 **Gitee** pull / push |

## 云端架构

```
三台机器  ──push/pull──►  Gitee（主云端，实时）
                            │
                  每天定时   │  GitHub Actions / Gitee 镜像
                            ▼
                         GitHub（只读备份）
```

- **Gitee（主）**：`https://gitee.com/gsg733jwb/cursor-dotfiles`
- **GitHub（镜像）**：`https://github.com/gsg733jwb-oss/cursor-dotfiles` — 三台机器**不直推**
- **项目仓库**（非 dotfiles）：`https://gitee.com/gsg733jwb/jiangwb.git`

镜像配置见 [docs/gitee-github-mirror.md](./docs/gitee-github-mirror.md)。

## 项目仓库（三机统一）

| Remote | 用途 | 示例 URL |
|--------|------|----------|
| `origin` | 默认 pull/push | `https://gitee.com/gsg733jwb/jiangwb.git` |
| `github` | 仅用户明确要求时 | `https://github.com/gsg733jwb-oss/jiangwb.git` |

各项目可在 `.cursor/rules/git-remotes.mdc` 写明 Agent 行为。

**任意机器开工（项目 + 配置）：**

```bash
git pull                                    # 项目代码（Gitee）
cd ~/cursor-dotfiles && ./sync.sh pull      # macOS 配置
# Windows: cd %USERPROFILE%\cursor-dotfiles && .\sync.ps1 pull
```

## 同步命令

| 时机 | macOS | Windows |
|------|-------|---------|
| 开工 | `cd ~/cursor-dotfiles && ./sync.sh pull` | `.\sync.ps1 pull` |
| 改完配置 | `./sync.sh push` | `.\sync.ps1 push` |

`push` = 收集本机 → commit → `git pull --rebase gitee` → **只推 Gitee**。

## 远程配置（clone / 已有仓库）

```bash
git remote add gitee https://gitee.com/gsg733jwb/cursor-dotfiles.git
git branch -u gitee/main main
# 勿将 origin 用于日常 push；若 origin 指向 GitHub 可保留只读或删除
```

新机器 clone：

```bash
git clone https://gitee.com/gsg733jwb/cursor-dotfiles.git ~/cursor-dotfiles
```

## 路径映射

| dotfiles | macOS | Windows |
|----------|-------|---------|
| `cursor/` | `~/.cursor/` | `%USERPROFILE%\.cursor\` |
| `editor/` | `~/Library/Application Support/Cursor/User/` | `%APPDATA%\Cursor\User\` |

## 同步内容

**进 Gitee：** rules、skills、mcp.json、hooks、editor 设置

**不进 Git：** skills-cursor、projects、聊天历史、密钥

## 编码习惯

- 回复语言：简体中文
- MCP 密钥用环境变量
- 项目代码独立仓库，与 dotfiles 分开

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-06-20 | 对等模式：三机均可 push |
| 2026-06-20 | Gitee 主云端；GitHub 每日镜像，机器不直推 GitHub |
