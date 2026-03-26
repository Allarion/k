#!/usr/bin/env bash

k_scope_list() {
  local file
  file="$(k_scopes_file)"
  [[ -f "$file" ]] || return 0
  cat "$file"
}

k_scope_exists() {
  local scope="$1"
  local file
  file="$(k_scopes_file)"
  [[ -f "$file" ]] || return 1
  grep -Fxq "$scope" "$file"
}

k_scope_show() {
  local scope
  if scope="$(k_get_current_scope)"; then
    printf '%s\n' "$scope"
  else
    k_die "No active scope set" 3
  fi
}

k_scope_use() {
  local scope="$1"
  [[ -n "$scope" ]] || k_die "Scope required" 2
  if ! k_scope_exists "$scope"; then
    k_warn "Scope not found in scopes.txt: $scope"
  fi
  k_current_scope_set "$scope"
  printf 'Active scope: %s\n' "$scope"
}

k_scope_clear() {
  k_current_scope_clear
  printf 'Active scope cleared\n'
}
