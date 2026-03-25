#!/usr/bin/env bash

k_journal_ensure_today_file() {
  local file
  file="$(k_journal_file_for_date)"
  if [[ ! -f "$file" ]]; then
    mkdir -p "$(dirname "$file")"
    cat > "$file" <<EOF2
---
date: $(k_today)
---

# $(k_today)
EOF2
  fi
  printf '%s\n' "$file"
}

k_journal_append() {
  local kind="$1"
  local scope="$2"
  local tags="$3"
  local text="$4"

  local file time_line scope_token tags_token
  file="$(k_journal_ensure_today_file)"
  time_line="$(k_time_hhmm)"
  scope_token=""
  tags_token=""

  [[ -n "$scope" ]] && scope_token=" [scope:$scope]"
  if [[ -n "$(k_normalize_tags "$tags")" ]]; then
    tags_token=" [tags:$(k_normalize_tags "$tags")]"
  fi

  {
    printf '\n## %s [%s]%s%s\n' "$time_line" "$kind" "$scope_token" "$tags_token"
    printf '%s\n' "$text"
  } >> "$file"

  printf '%s\n' "$file"
}

k_journal_show_today() {
  local file
  file="$(k_journal_ensure_today_file)"
  cat "$file"
}

k_journal_edit_today() {
  local file
  file="$(k_journal_ensure_today_file)"
  k_open_editor "$file"
}

k_journal_last_scope_entries() {
  local scope="$1"
  local limit="${2:-5}"
  local file
  file="$(k_journal_file_for_date)"
  [[ -f "$file" ]] || return 0
  awk -v scope="$scope" '
    /^## / {header=$0; next}
    NF==0 {next}
    header ~ "\\[scope:" scope "\\]" {print header " :: " $0}
  ' "$file" | tail -n "$limit"
}

k_journal_last_wrap() {
  local file
  file="$(k_journal_file_for_date)"
  [[ -f "$file" ]] || return 0
  awk '
    /^## .*\[wrap\]/ {header=$0; next}
    NF==0 {next}
    header != "" {print header " :: " $0; header=""}
  ' "$file" | tail -n1
}
