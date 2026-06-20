# 我的 Cursor 多机环境

> 给 Agent 读的环境说明。聊天历史不能跨机同步；以本文件 + `cursor/rules/multi-machine.mdc` 为准。

## 机器角色

| 机器 | 角色 | Git / 同步 |
|------|------|------------|
| **macOS**（本机） | 主机器 | 唯一允许 `git push` 和 `./sync.sh push` |
| **Windows × 2** | 从机器 | 只做 `git pull` + `.\sync.ps1 pull`，**禁止 push** |

## 配置同步

- **个人配置仓库**：`~/cursor-dotfiles`（GitHub + Gitee 双远程，互为备份）
- **GitHub**：`https://github.com/gsg733jwb-oss/cursor-dotfiles`
- **Gitee**：`https://gitee.com/gsg733jwb/cursor-dotfiles`（账号 `gsg733jwb`；项目仓库 `jiangwb` 见下，与 dotfiles 分开）
- **Gitee 项目仓库**（非 dotfiles）：`https://gitee.com/gsg733jwb/jiangwb.git`
- **Mac 同步**：`cd ~/cursor-dotfiles && ./sync.sh pull|push`
- **Windows 同步**：`cd %USERPROFILE%\cursor-dotfiles && .\sync.ps1 pull`
- **项目级规则**：写在各项目 `.cursor/rules/`，**不进** dotfiles

## 路径映射

### macOS（主）

| dotfiles 目录 | 本机路径 |
|---------------|----------|
| `cursor/` | `~/.cursor/` |
| `editor/` | `~/Library/Application Support/Cursor/User/` |

### Windows

| dotfiles 目录 | 本机路径 |
|---------------|----------|
| `cursor/` | `%USERPROFILE%\.cursor\` |
| `editor/` | `%APPDATA%\Cursor\User\` |

## 同步内容

**会同步（进 Git）：**

- `cursor/rules/` — 全局 Rules（含 `multi-machine.mdc`）
- `cursor/skills/` — 自定义 Skills
- `cursor/mcp.json` — MCP 配置（**密钥用环境变量**，不写明文）
- `cursor/hooks/` — Cursor Hooks
- `editor/settings.json`、`editor/keybindings.json` 等编辑器设置

**不同步（留在本机）：**

- `~/.cursor/skills-cursor/` — Cursor 内置，各机自动维护
- `~/.cursor/projects/` — 项目缓存、MCP 描述符
- 聊天历史、`agent-transcripts/`、`chats/`
- MCP 密钥、`.env`、token 文件

## 工作流

### 在 Mac 上改配置

1. 在 Cursor 里改 Rules / Skills / MCP / 设置，或直接改 `~/.cursor/`、`editor/`
2. `cd ~/cursor-dotfiles && ./sync.sh push`（收集变更 → commit → 推 GitHub + Gitee）
3. 新开 Agent 对话即可；`alwaysApply` 规则会自动生效

### 在 Windows 上开工

1. `cd %USERPROFILE%\cursor-dotfiles`
2. `git pull`（或 `git pull gitee main`）
3. `.\sync.ps1 pull`
4. 重启 Cursor 或新开对话

### 让 Agent 接上上下文

- 首次或重要变更后：`@AGENTS.md` 并说「按多机约定继续」
- 日常：`multi-machine.mdc` 已 `alwaysApply: true`，一般不必每次重复

## 编码与沟通习惯

- **回复语言**：简体中文
- **Git**：未经明确要求不 commit / push；Mac 为唯一 push 机器
- **密钥**：MCP API Key 等用环境变量或本机 secret，禁止提交明文
- **项目代码**：各项目独立仓库（如 `kl-travel-guide`），与 dotfiles 分开

## 当前任务

- [x] Mac 上创建 `cursor-dotfiles` 与 `AGENTS.md`、`multi-machine.mdc`
- [ ] 初始化 Git 仓库并添加 GitHub + Gitee 双远程
- [ ] Mac 首次 `./sync.sh push`
- [ ] 两台 Windows clone 并 `.\sync.ps1 pull`
- [ ] 验证三机 Rules / Skills 一致

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-06-20 | 初版：三机约定、双远程、Mac 主 push |
