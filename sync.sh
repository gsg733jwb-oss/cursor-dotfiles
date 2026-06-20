#!/usr/bin/env bash
# cursor-dotfiles sync — macOS only (主机器)
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CURSOR_HOME="${HOME}/.cursor"
EDITOR_USER="${HOME}/Library/Application Support/Cursor/User"

die() { echo "error: $*" >&2; exit 1; }

ensure_dirs() {
  mkdir -p "${DOTFILES}/cursor/rules"
  mkdir -p "${DOTFILES}/cursor/skills"
  mkdir -p "${DOTFILES}/cursor/hooks"
  mkdir -p "${DOTFILES}/editor"
  mkdir -p "${CURSOR_HOME}/rules"
  mkdir -p "${CURSOR_HOME}/skills"
}

collect_from_live() {
  ensure_dirs

  if [[ -d "${CURSOR_HOME}/rules" ]]; then
    rsync -a --delete "${CURSOR_HOME}/rules/" "${DOTFILES}/cursor/rules/"
  fi

  if [[ -d "${CURSOR_HOME}/skills" ]]; then
    rsync -a --delete "${CURSOR_HOME}/skills/" "${DOTFILES}/cursor/skills/"
  fi

  if [[ -f "${CURSOR_HOME}/mcp.json" ]]; then
    cp "${CURSOR_HOME}/mcp.json" "${DOTFILES}/cursor/mcp.json"
  fi

  if [[ -d "${CURSOR_HOME}/hooks" ]]; then
    rsync -a "${CURSOR_HOME}/hooks/" "${DOTFILES}/cursor/hooks/"
  fi

  for f in settings.json keybindings.json; do
    if [[ -f "${EDITOR_USER}/${f}" ]]; then
      cp "${EDITOR_USER}/${f}" "${DOTFILES}/editor/${f}"
    fi
  done

  echo "collected live config → ${DOTFILES}"
}

apply_to_live() {
  ensure_dirs

  if [[ -d "${DOTFILES}/cursor/rules" ]]; then
    rsync -a "${DOTFILES}/cursor/rules/" "${CURSOR_HOME}/rules/"
  fi

  if [[ -d "${DOTFILES}/cursor/skills" ]] && [[ -n "$(ls -A "${DOTFILES}/cursor/skills" 2>/dev/null || true)" ]]; then
    rsync -a "${DOTFILES}/cursor/skills/" "${CURSOR_HOME}/skills/"
  fi

  if [[ -f "${DOTFILES}/cursor/mcp.json" ]]; then
    cp "${DOTFILES}/cursor/mcp.json" "${CURSOR_HOME}/mcp.json"
  fi

  if [[ -d "${DOTFILES}/cursor/hooks" ]] && [[ -n "$(ls -A "${DOTFILES}/cursor/hooks" 2>/dev/null || true)" ]]; then
    mkdir -p "${CURSOR_HOME}/hooks"
    rsync -a "${DOTFILES}/cursor/hooks/" "${CURSOR_HOME}/hooks/"
  fi

  mkdir -p "${EDITOR_USER}"
  for f in settings.json keybindings.json; do
    if [[ -f "${DOTFILES}/editor/${f}" ]]; then
      cp "${DOTFILES}/editor/${f}" "${EDITOR_USER}/${f}"
    fi
  done

  echo "applied ${DOTFILES} → live (~/.cursor + editor)"
}

push_remote() {
  collect_from_live
  cd "${DOTFILES}"
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    die "not a git repo — run: git init && git remote add origin <url>"
  fi
  git add -A
  if git diff --staged --quiet; then
    echo "nothing to commit"
  else
    git commit -m "sync: $(date +%Y-%m-%d\ %H:%M)"
  fi
  git push origin main 2>/dev/null || git push origin master 2>/dev/null || git push origin HEAD
  if git remote get-url gitee >/dev/null 2>&1; then
    git push gitee main 2>/dev/null || git push gitee master 2>/dev/null || git push gitee HEAD
  fi
}

usage() {
  cat <<'EOF'
Usage: ./sync.sh [pull|push]

  pull  repo → ~/.cursor/ + editor（默认）
  push  收集本机配置 → commit → 推远程（仅 macOS 主机器）
EOF
}

cmd="${1:-pull}"
case "${cmd}" in
  pull) apply_to_live ;;
  push) push_remote ;;
  -h|--help) usage ;;
  *) usage; die "unknown command: ${cmd}" ;;
esac
