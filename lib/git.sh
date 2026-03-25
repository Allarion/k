#!/usr/bin/env bash

k_git_is_repo() {
  git -C "$(k_repo_root)" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

k_git_init_repo() {
  git -C "$1" init >/dev/null
}

k_git_commit_enabled() {
  k_load_config
  [[ "$K_GIT_AUTO_COMMIT" == "true" ]]
}

k_git_commit_if_enabled() {
  local message="$1"
  k_git_commit_enabled || return 0
  k_git_commit "$message"
}

k_git_commit() {
  local message="$1"
  local repo
  repo="$(k_repo_root)"
  git -C "$repo" add .
  if git -C "$repo" diff --cached --quiet; then
    return 0
  fi
  if ! git -C "$repo" commit -m "$message" >/dev/null 2>&1; then
    k_die "Git commit failed. Configure git user.name and user.email for this repo or globally." 5
  fi
}
