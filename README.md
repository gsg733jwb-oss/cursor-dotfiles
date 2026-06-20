# cursor-dotfiles

个人 Cursor 配置，三机对等同步。

**Gitee = 主云端**（三台机器 push/pull）  
**GitHub = 只读镜像**（每天自动从 Gitee 同步，机器不直推）

## 快速开始

```bash
git clone https://gitee.com/gsg733jwb/cursor-dotfiles.git ~/cursor-dotfiles
cd ~/cursor-dotfiles
./sync.sh pull      # macOS；Windows 用 .\sync.ps1 pull
```

改完配置：

```bash
./sync.sh push      # 仅推 Gitee
```

| 时机 | 命令 |
|------|------|
| 开工 | `pull` |
| 改完配置 | `push` |

## Gitee → GitHub 每日镜像

见 [docs/gitee-github-mirror.md](./docs/gitee-github-mirror.md)。

已包含 **GitHub Actions** 工作流（每天自动 mirror Gitee → GitHub）。合并到 GitHub 后在 Actions 页手动跑一次验证。

## 目录结构

```
cursor-dotfiles/
├── AGENTS.md
├── sync.sh / sync.ps1
├── cursor/rules|skills|hooks|mcp.json
├── editor/
├── docs/gitee-github-mirror.md
└── .github/workflows/sync-from-gitee.yml
```

## 注意

- 三台机器 **不要** `git push` 到 GitHub
- `skills-cursor/`、聊天历史不同步
