#!/usr/bin/env bash
# 安装 Mac 开机自启配置监听 + 便捷命令 symlink
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME}"
LABEL="com.gsg733jwb.cursor-sync-watch"
PLIST_SRC="${DOTFILES}/launchd/com.gsg733jwb.cursor-sync-watch.plist.template"
PLIST_DST="${HOME_DIR}/Library/LaunchAgents/${LABEL}.plist"

chmod +x "${DOTFILES}/scripts/"*.sh
chmod +x "${DOTFILES}/cursor/hooks/"*.sh 2>/dev/null || true

ln -sf "${DOTFILES}/scripts/cursor-sync.sh" "${HOME_DIR}/cursor-sync.sh"

sed "s|__HOME__|${HOME_DIR}|g" "${PLIST_SRC}" > "${PLIST_DST}"

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "${PLIST_DST}"
launchctl enable "gui/$(id -u)/${LABEL}" 2>/dev/null || true

# 确保 hooks.json 已应用到 ~/.cursor
"${DOTFILES}/sync.sh" pull

echo "installed:"
echo "  ~/cursor-sync.sh -> scripts/cursor-sync.sh"
echo "  LaunchAgent: ${LABEL}"
echo "  log: ~/.cursor/sync-auto.log"
