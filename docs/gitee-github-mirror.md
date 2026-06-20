# Gitee → GitHub 镜像说明

三台机器**只 push Gitee**。GitHub 作为只读备份，每日自动与 Gitee 对齐。

## 方案 A：GitHub Actions（已配置，推荐）

仓库内已有 [`.github/workflows/sync-from-gitee.yml`](../.github/workflows/sync-from-gitee.yml)：

- **触发**：每天 UTC 16:00（约北京时间 0 点）+ 可手动 `workflow_dispatch`
- **逻辑**：从 Gitee clone → mirror push 到 GitHub
- **权限**：使用仓库自带 `GITHUB_TOKEN`，无需三台机器参与

首次合并到 GitHub 后，在 GitHub 仓库 **Actions** 页手动跑一次 **Sync from Gitee** 验证。

## 方案 B：Gitee 仓库镜像（推送镜像）

若 Gitee 账号支持「仓库镜像管理」：

1. 打开 [cursor-dotfiles 设置](https://gitee.com/gsg733jwb/cursor-dotfiles/settings#mirrors)
2. **添加镜像** → 目标选 GitHub
3. 填写 `https://github.com/gsg733jwb/cursor-dotfiles.git` 及 GitHub PAT
4. 可选：**仅定时同步**（若界面支持 cron），或每次 push 到 Gitee 时同步

与方案 A 二选一即可，避免双向重复推送。

## 方案 C：Gitee Go 定时流水线

在 Gitee → 流水线 → 新建定时任务，执行：

```bash
git clone --bare https://gitee.com/gsg733jwb/cursor-dotfiles.git repo.git
cd repo.git
git push --mirror https://<GITHUB_PAT>@github.com/gsg733jwb-oss/cursor-dotfiles.git
```

将 `GITHUB_PAT` 存为流水线密钥变量。

## 远程配置（三台机器统一）

```bash
git remote remove origin          # 若 origin 仍指向 GitHub，可删掉或改名
git remote add gitee https://gitee.com/gsg733jwb/cursor-dotfiles.git
git branch -u gitee/main main
```

clone 新机器时直接用 Gitee：

```bash
git clone https://gitee.com/gsg733jwb/cursor-dotfiles.git ~/cursor-dotfiles
```

## 数据流

```
Mac / Win1 / Win2  ──push/pull──►  Gitee（主云端）
                                      │
                            每天定时   │
                                      ▼
                                   GitHub（只读镜像）
```
