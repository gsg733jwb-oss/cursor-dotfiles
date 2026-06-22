#!/usr/bin/env bash
# Start weixin listener (stop plain poll --watch if running)
set -euo pipefail
TARGET="${HOME}/.weixin-mcp"
LISTENER="${TARGET}/weixin-listener.mjs"
LOG="${TARGET}/listener.log"

if [[ ! -f "${LISTENER}" ]]; then
  "$(cd "$(dirname "$0")" && pwd)/install-weixin-listener.sh"
fi

pkill -f "weixin-mcp poll --watch" 2>/dev/null || true
pkill -f "weixin-listener.mjs" 2>/dev/null || true
sleep 0.3

nohup node "${LISTENER}" >> "${LOG}" 2>&1 &
echo "weixin-listener pid $! (log: ${LOG})"
