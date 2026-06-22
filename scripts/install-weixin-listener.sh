#!/usr/bin/env bash
# Install weixin two-phase listener → ~/.weixin-mcp/
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${HOME}/.weixin-mcp"
mkdir -p "${TARGET}/inbox" "${TARGET}/outbox"
cp "${DIR}/weixin/weixin-listener.mjs" "${TARGET}/"
chmod +x "${TARGET}/weixin-listener.mjs"
echo "Installed → ${TARGET}/weixin-listener.mjs"
echo "Start: node ${TARGET}/weixin-listener.mjs"
