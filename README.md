# cursor-dotfiles

个人 Cursor 配置，在三台机器间通过 Git 同步（GitHub + Gitee 双远程）。

**模型**：Git 远程 = 云端。Mac 与 Windows **权限相同**，任意机器可 `pull` / `push`。

## 快速开始

### macOS

```bash
git clone https://github.com/gsg733jwb-oss/cursor-dotfiles.git ~/cursor-dotfiles
cd ~/cursor-dotfiles
./sync.sh pull    # 首次：云端 → 本机
```

改完配置后：

```bash
./sync.sh push    # 本机 → 云端（GitHub + Gitee）
```

### Windows

```powershell
git clone https://github.com/gsg733jwb-oss/cursor-dotfiles.git $env:USERPROFILE\cursor-dotfiles
cd $env:USERPROFILE\cursor-dotfiles
.\sync.ps1 pull
```

改完配置后：

```powershell
.\sync.ps1 push
```

### 日常节奏

| 时机 | 命令 |
|------|------|
| 开工 | `pull` |
| 改完 Rules / Skills / MCP / 设置 | `push` |
| 开完工一条龙 | `sync`（pull + push） |

## 目录结构

```
cursor-dotfiles/
├── README.md
├── AGENTS.md
├── sync.sh          # macOS
├── sync.ps1         # Windows
├── cursor/
│   ├── rules/
│   ├── skills/
│   ├── mcp.json
│   └── hooks/
└── editor/
```

## 双远程

```bash
git remote add origin https://github.com/gsg733jwb-oss/cursor-dotfiles.git
git remote add gitee   https://gitee.com/gsg733jwb/cursor-dotfiles.git
```

`push` 会同时推送到 `origin` 和 `gitee`。

## 不同步的内容

- `skills-cursor/`（Cursor 内置）
- `projects/`、聊天历史
- 密钥与 `.env`

详见 [AGENTS.md](./AGENTS.md)。
