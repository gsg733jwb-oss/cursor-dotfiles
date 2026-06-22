#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/.weixin-mcp"
SCRIPT="$DIR/weixin-watcher.mjs"
LOG="$DIR/watcher.log"

if [[ ! -f "$SCRIPT" ]]; then
  echo "找不到 $SCRIPT，请先运行 install-mac-watcher.sh" >&2
  exit 1
fi

if pgrep -f "weixin-watcher.mjs" >/dev/null 2>&1; then
  echo "监听器已在运行"
  exit 0
fi

nohup node "$SCRIPT" >>"$LOG" 2>&1 &
echo "微信监听器已启动 (PID $!)"
echo "日志: $LOG"
echo "配置: $DIR/watcher.config.json"
