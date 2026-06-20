#!/usr/bin/env bash
# 轮询监听 Cursor 配置变更，触发防抖上传（无需 fswatch）
set -euo pipefail

DOTFILES="${HOME}/cursor-dotfiles"
AUTO="${DOTFILES}/scripts/cursor-sync-auto.sh"
LOG="${HOME}/.cursor/sync-auto.log"
INTERVAL="${CURSOR_SYNC_POLL:-10}"
STATE="${HOME}/.cursor/.sync-watch.state"

CURSOR_HOME="${HOME}/.cursor"
EDITOR_USER="${HOME}/Library/Application Support/Cursor/User"

watch_paths() {
  [[ -d "${CURSOR_HOME}/rules" ]] && find "${CURSOR_HOME}/rules" -type f 2>/dev/null
  [[ -d "${CURSOR_HOME}/skills" ]] && find "${CURSOR_HOME}/skills" -type f 2>/dev/null
  [[ -d "${CURSOR_HOME}/hooks" ]] && find "${CURSOR_HOME}/hooks" -type f 2>/dev/null
  [[ -f "${CURSOR_HOME}/mcp.json" ]] && echo "${CURSOR_HOME}/mcp.json"
  [[ -f "${CURSOR_HOME}/hooks.json" ]] && echo "${CURSOR_HOME}/hooks.json"
  for f in settings.json keybindings.json; do
    [[ -f "${EDITOR_USER}/${f}" ]] && echo "${EDITOR_USER}/${f}"
  done
}

snapshot() {
  watch_paths | while read -r f; do
    [[ -f "$f" ]] && stat -f '%N %m' "$f" 2>/dev/null
  done | sort
}

echo "[$(date)] cursor-sync-watch started (poll ${INTERVAL}s)" >> "${LOG}"
snapshot > "${STATE}"

while true; do
  sleep "${INTERVAL}"
  current="$(snapshot)"
  previous="$(cat "${STATE}" 2>/dev/null || true)"
  if [[ "${current}" != "${previous}" ]]; then
    echo "${current}" > "${STATE}"
    echo "[$(date)] config change detected" >> "${LOG}"
    "${AUTO}"
  fi
done
