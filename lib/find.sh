#!/usr/bin/env bash

k_find_run() {
  local query="$1"
  [[ -n "$query" ]] || k_die "Query required" 2
  if command -v rg >/dev/null 2>&1; then
    rg -n --hidden --glob '!.git' --glob '!.knowledge/current_scope' "$query" "$(k_repo_root)"
  else
    grep -RIn "$query" "$(k_repo_root)"
  fi
}
