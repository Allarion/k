#!/usr/bin/env bash

k_resume_show() {
  local scope="$1"
  printf 'Scope: %s\n\n' "$scope"

  printf 'Todo Summary:\n'
  printf -- '- %s\n' "$(k_todo_status_summary "$scope")"

  printf '\nRecent Journal:\n'
  local recent
  recent="$(k_journal_last_scope_entries "$scope" 5 || true)"
  if [[ -n "$recent" ]]; then
    printf '%s\n' "$recent" | sed 's/^/- /'
  else
    printf '%s\n' '- none'
  fi

  printf '\nIn Progress:\n'
  local progress_todos
  progress_todos="$(k_todo_progress_titles "$scope" || true)"
  if [[ -n "$progress_todos" ]]; then
    printf '%s\n' "$progress_todos" | sed 's/^/- /'
  else
    printf '%s\n' '- none'
  fi

  printf '\nOpen Todos:\n'
  local todos
  todos="$(k_todo_open_titles "$scope" || true)"
  if [[ -n "$todos" ]]; then
    printf '%s\n' "$todos" | sed 's/^/- /'
  else
    printf '%s\n' '- none'
  fi

  printf '\nDrafts:\n'
  local match=0 f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    printf -- '- %s\n' "$(basename "$f")"
    match=1
  done < <(k_entry_list_scope_drafts "$scope")
  [[ "$match" -eq 1 ]] || printf '%s\n' '- none'

  printf '\nLatest Entry:\n'
  local latest_entry latest_type latest_title
  latest_entry="$(k_entry_latest_for_scope "$scope" || true)"
  if [[ -n "$latest_entry" ]]; then
    latest_type="$(k_entry_frontmatter_get "$latest_entry" type)"
    latest_title="$(k_entry_frontmatter_get "$latest_entry" title)"
    printf -- '- [%s] %s\n' "$latest_type" "$latest_title"
  else
    printf '%s\n' '- none'
  fi

  printf '\nLatest Wrap:\n'
  local wrap
  wrap="$(k_journal_last_wrap || true)"
  if [[ -n "$wrap" ]]; then
    printf -- '- %s\n' "$wrap"
  else
    printf '%s\n' '- none'
  fi
}
