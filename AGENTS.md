# 我的 Cursor 多机环境

> 给 Agent 读的环境说明。聊天历史不能跨机同步；以本文件 + `cursor/rules/multi-machine.mdc` 为准。

## 机器角色（对等）

| 机器 | 权限 |
|------|------|
| **macOS × 1** | pull / push，与 Windows 相同 |
| **Windows × 2** | pull / push，与 Mac 相同 |

**Git 远程 = 云端配置源**。任意机器都可以改、都可以推；其他机器 pull 后保持一致。

## 配置同步

- **仓库**：`~/cursor-dotfiles`（GitHub + Gitee 双远程）
- **GitHub**：`https://github.com/gsg733jwb-oss/cursor-dotfiles`
- **Gitee**：`https://gitee.com/gsg733jwb/cursor-dotfiles`
- **Gitee 项目仓库**（非 dotfiles）：`https://gitee.com/gsg733jwb/jiangwb.git`
- **Mac**：`cd ~/cursor-dotfiles && ./sync.sh pull|push|sync`
- **Windows**：`cd %USERPROFILE%\cursor-dotfiles && .\sync.ps1 pull|push|sync`
- **项目级规则**：各项目 `.cursor/rules/`，不进 dotfiles

## 路径映射

### macOS

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

**进 Git（云端）：** `cursor/rules/`、`cursor/skills/`、`cursor/mcp.json`、`cursor/hooks/`、`editor/settings.json` 等

**不进 Git：** `skills-cursor/`、`projects/`、聊天历史、密钥与 `.env`

## 工作流

### 开工（任意机器）

```bash
# Mac
cd ~/cursor-dotfiles && ./sync.sh pull

# Windows
cd $env:USERPROFILE\cursor-dotfiles; .\sync.ps1 pull
```

### 改完配置（任意机器）

```bash
# Mac
cd ~/cursor-dotfiles && ./sync.sh push

# Windows
cd $env:USERPROFILE\cursor-dotfiles; .\sync.ps1 push
```

`push` 会：收集本机配置 → commit → `git pull --rebase` → 推 GitHub + Gitee。

### 让 Agent 接上上下文

- `@AGENTS.md` +「按多机约定继续」
- 日常靠 `multi-machine.mdc`（`alwaysApply: true`）

## 编码与沟通习惯

- **回复语言**：简体中文
- **密钥**：MCP 用环境变量，禁止提交明文
- **项目代码**：独立仓库（如 `kl-travel-guide`），与 dotfiles 分开

## 当前任务

- [x] 三机 dotfiles 仓库与双远程
- [x] 对等权限：任意机器 pull / push
- [ ] 两台 Windows clone 并首次 `.\sync.ps1 pull`
- [ ] 三机验证配置一致

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-06-20 | 初版：双远程、Mac 主 push |
| 2026-06-20 | 改为对等模式：Git 作云端，三机均可 push |
