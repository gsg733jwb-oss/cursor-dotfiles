#!/usr/bin/env bash
# 防抖后自动 push 到 Gitee（Mac / Linux）
set -euo pipefail

DOTFILES="${HOME}/cursor-dotfiles"
LOG="${HOME}/.cursor/sync-auto.log"
TOKEN_FILE="${HOME}/.cursor/.sync-debounce.token"
SUPPRESS="${HOME}/.cursor/.sync-suppress"
DEBOUNCE_SEC="${CURSOR_SYNC_DEBOUNCE:-45}"

mkdir -p "${HOME}/.cursor"

if [[ -f "${SUPPRESS}" ]]; then
  exit 0
fi

token="$(date +%s%N 2>/dev/null || date +%s)"
echo "${token}" > "${TOKEN_FILE}"

(
  sleep "${DEBOUNCE_SEC}"
  [[ -f "${SUPPRESS}" ]] && exit 0
  [[ "$(cat "${TOKEN_FILE}" 2>/dev/null || true)" != "${token}" ]] && exit 0
  {
    echo "[$(( $(date +%s) ))] auto push start"
    "${DOTFILES}/scripts/cursor-sync.sh" push
    echo "[$(( $(date +%s) ))] auto push done"
  } >> "${LOG}" 2>&1
) &
