# cursor-dotfiles

个人 Cursor 配置，在三台机器间通过 Git 同步（GitHub + Gitee 双远程）。

## 快速开始

### macOS（主机器）

```bash
git clone https://github.com/gsg733jwb-oss/cursor-dotfiles.git ~/cursor-dotfiles
cd ~/cursor-dotfiles
./sync.sh pull    # 首次：把 rules 等同步到 ~/.cursor/
```

改完配置后：

```bash
./sync.sh push    # 收集 → commit → 推 GitHub + Gitee
```

### Windows（从机器）

```powershell
git clone https://github.com/gsg733jwb-oss/cursor-dotfiles.git $env:USERPROFILE\cursor-dotfiles
cd $env:USERPROFILE\cursor-dotfiles
.\sync.ps1 pull
```

每次开工前：

```powershell
git pull
.\sync.ps1 pull
```

**不要在 Windows 上 push。**

## 目录结构

```
cursor-dotfiles/
├── README.md              # 本文件（给人看）
├── AGENTS.md              # 给 Agent 看的环境说明
├── sync.sh                # macOS 同步脚本
├── sync.ps1               # Windows 同步脚本
├── cursor/
│   ├── rules/             # → ~/.cursor/rules/
│   ├── skills/            # → ~/.cursor/skills/
│   ├── mcp.json           # → ~/.cursor/mcp.json
│   └── hooks/             # → ~/.cursor/hooks/
└── editor/                # → Cursor User 设置目录
```

## 双远程

Gitee 账号：`gsg733jwb`（项目仓库 [jiangwb](https://gitee.com/gsg733jwb/jiangwb) 与 Cursor 配置分开管理）。

```bash
git remote add origin https://github.com/gsg733jwb-oss/cursor-dotfiles.git
git remote add gitee   https://gitee.com/gsg733jwb/cursor-dotfiles.git
```

在 Gitee 上需**新建**空仓库 `cursor-dotfiles`（不要与 `jiangwb` 混用）。

`./sync.sh push` 会同时推送到 `origin` 和 `gitee`（若已配置）。

## 不同步的内容

- `skills-cursor/`（Cursor 内置）
- `projects/`、聊天历史
- 密钥与 `.env`

详见 [AGENTS.md](./AGENTS.md)。
