#!/usr/bin/env bash
# Install browser QR login for weixin-mcp → ~/.weixin-mcp/
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${HOME}/.weixin-mcp"
mkdir -p "${TARGET}"
cp "${DIR}/weixin/qr-login-server.mjs" "${TARGET}/"
cp "${DIR}/weixin/package.json" "${TARGET}/"
cd "${TARGET}"
npm install --silent
echo "Installed → ${TARGET}"
echo "Run: node ${TARGET}/qr-login-server.mjs"
