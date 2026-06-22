#!/usr/bin/env bash
set -euo pipefail

PIDS=$(pgrep -f "weixin-watcher.mjs" || true)
if [[ -z "$PIDS" ]]; then
  echo "监听器未运行"
  exit 0
fi

echo "$PIDS" | xargs kill -TERM 2>/dev/null || true
sleep 1
echo "$PIDS" | xargs kill -KILL 2>/dev/null || true
echo "监听器已停止"
