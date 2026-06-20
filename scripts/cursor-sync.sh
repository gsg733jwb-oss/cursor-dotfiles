#!/usr/bin/env bash
# pull / push 包装：pull 期间抑制自动上传
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
SUPPRESS="${HOME}/.cursor/.sync-suppress"
ACTION="${1:-pull}"

case "${ACTION}" in
  pull)
    mkdir -p "${HOME}/.cursor"
    touch "${SUPPRESS}"
    trap 'rm -f "${SUPPRESS}"' EXIT
    "${DOTFILES}/sync.sh" pull
    ;;
  push|sync)
    "${DOTFILES}/sync.sh" "${ACTION}"
    ;;
  -h|--help)
    echo "Usage: cursor-sync.sh [pull|push|sync]"
    ;;
  *)
    "${DOTFILES}/sync.sh" "${ACTION}"
    ;;
esac
