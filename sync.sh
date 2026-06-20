#!/usr/bin/env bash
# cursor-dotfiles sync — macOS / Linux（三机对等，Git 为「云端」）
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

git_pull() {
  cd "${DOTFILES}"
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    die "not a git repo"
  fi
  git pull --rebase origin main 2>/dev/null \
    || git pull --rebase origin master 2>/dev/null \
    || git pull --rebase
}

git_push_all() {
  cd "${DOTFILES}"
  git push origin main 2>/dev/null || git push origin master 2>/dev/null || git push origin HEAD
  if git remote get-url gitee >/dev/null 2>&1; then
    git push gitee main 2>/dev/null || git push gitee master 2>/dev/null || git push gitee HEAD
  fi
}

pull_remote() {
  git_pull
  apply_to_live
}

push_remote() {
  collect_from_live
  cd "${DOTFILES}"
  git add -A
  if git diff --staged --quiet; then
    echo "nothing to commit"
  else
    git commit -m "sync: $(date +%Y-%m-%d\ %H:%M) ($(hostname -s 2>/dev/null || echo mac))"
  fi
  git_pull
  git_push_all
  echo "pushed to remote (GitHub + Gitee)"
}

sync_both() {
  pull_remote
  push_remote
}

usage() {
  cat <<'EOF'
Usage: ./sync.sh [pull|push|sync]

  pull  从云端拉取 → 应用到本机（开工时用）
  push  收集本机配置 → commit → 拉取合并 → 推云端（改完配置后用）
  sync  pull + push（开完工一条龙）

三台机器权限相同，任意一台都可 pull / push。
EOF
}

cmd="${1:-pull}"
case "${cmd}" in
  pull) pull_remote ;;
  push) push_remote ;;
  sync) sync_both ;;
  -h|--help) usage ;;
  *) usage; die "unknown command: ${cmd}" ;;
esac
