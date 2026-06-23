#!/usr/bin/env bash
# Cursor hook: 编辑配置文件后触发防抖上传（macOS）
set -euo pipefail

raw="$(cat || true)"
[[ -z "${raw}" ]] && exit 0

watch_re='\.cursor/(rules|skills|hooks)|\.cursor/mcp\.json|\.cursor/hooks\.json|Application Support/Cursor/User/(settings|keybindings)\.json'
if ! printf '%s' "${raw}" | grep -qE "${watch_re}"; then
  exit 0
fi

exec "${HOME}/cursor-dotfiles/scripts/cursor-sync-auto.sh"
