#!/usr/bin/env bash
# 在 Mac 上安装微信监听器到 ~/.weixin-mcp
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.weixin-mcp"

mkdir -p "$DEST"
cp "$SRC/weixin-watcher.mjs" "$DEST/"
cp "$SRC/qr-login-server.mjs" "$DEST/"
if [[ ! -f "$DEST/watcher.config.json" ]]; then
  cp "$SRC/watcher.config.json" "$DEST/"
fi
chmod +x "$SRC/start-watcher.sh" "$SRC/stop-watcher.sh"

echo "已安装到 $DEST"
echo ""
echo "下一步："
echo "  1. 确保 agent CLI 可用: agent --version"
echo "  2. 微信扫码登录: node $DEST/qr-login-server.mjs（或 npx weixin-mcp login）"
echo "  3. 启动监听器: bash $SRC/start-watcher.sh"
echo "  4. 查看日志: tail -f $DEST/watcher.log"
