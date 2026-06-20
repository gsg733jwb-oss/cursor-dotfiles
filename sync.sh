#!/usr/bin/env bash
# cursor-dotfiles sync — macOS / Linux
# 三台机器只与 Gitee 同步；GitHub 由 Gitee/定时任务镜像，本机不 push GitHub
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CURSOR_HOME="${HOME}/.cursor"
EDITOR_USER="${HOME}/Library/Application Support/Cursor/User"
GIT_REMOTE="${GIT_REMOTE:-gitee}"

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

  if [[ -f "${CURSOR_HOME}/hooks.json" ]]; then
    cp "${CURSOR_HOME}/hooks.json" "${DOTFILES}/cursor/hooks.macos.json"
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

  if [[ -f "${DOTFILES}/cursor/hooks.macos.json" ]]; then
    cp "${DOTFILES}/cursor/hooks.macos.json" "${CURSOR_HOME}/hooks.json"
  elif [[ -f "${DOTFILES}/cursor/hooks.json" ]]; then
    cp "${DOTFILES}/cursor/hooks.json" "${CURSOR_HOME}/hooks.json"
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
  if ! git remote get-url "${GIT_REMOTE}" >/dev/null 2>&1; then
    die "remote '${GIT_REMOTE}' not found — add: git remote add gitee https://gitee.com/gsg733jwb/cursor-dotfiles.git"
  fi
  git pull --rebase "${GIT_REMOTE}" main 2>/dev/null \
    || git pull --rebase "${GIT_REMOTE}" master 2>/dev/null \
    || git pull --rebase "${GIT_REMOTE}"
}

git_push() {
  cd "${DOTFILES}"
  git push "${GIT_REMOTE}" main 2>/dev/null \
    || git push "${GIT_REMOTE}" master 2>/dev/null \
    || git push "${GIT_REMOTE}" HEAD
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
    git commit -m "sync: $(date +%Y-%m-%d\ %H:%M) ($(hostname -s 2>/dev/null || echo host))"
  fi
  git_pull
  git_push
  echo "pushed to Gitee (${GIT_REMOTE}) — GitHub 由定时镜像更新，本机不直推"
}

sync_both() {
  pull_remote
  push_remote
}

usage() {
  cat <<'EOF'
Usage: ./sync.sh [pull|push|sync]

  pull  从 Gitee 拉取 → 应用到本机
  push  收集本机 → commit → 拉取合并 → 仅推 Gitee
  sync  pull + push

三台机器只 push Gitee；GitHub 每日由仓库镜像 / GitHub Actions 同步。
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
