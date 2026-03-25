#!/usr/bin/env bash

k_resume_show() {
  local scope="$1"
  printf 'Scope: %s\n\n' "$scope"

  printf 'Zuletzt:\n'
  local recent
  recent="$(k_journal_last_scope_entries "$scope" 5 || true)"
  if [[ -n "$recent" ]]; then
    printf '%s\n' "$recent" | sed 's/^/- /'
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
  local drafts match=0 f dscope
  if [[ -d "$(k_drafts_dir)" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      dscope="$(k_entry_frontmatter_get "$f" scope 2>/dev/null || true)"
      if [[ "$dscope" == "$scope" ]]; then
        printf -- '- %s\n' "$(basename "$f")"
        match=1
      fi
    done < <(find "$(k_drafts_dir)" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
  fi
  [[ "$match" -eq 1 ]] || printf '%s\n' '- none'

  printf '\nLetzter Wrap:\n'
  local wrap
  wrap="$(k_journal_last_wrap || true)"
  if [[ -n "$wrap" ]]; then
    printf -- '- %s\n' "$wrap"
  else
    printf '%s\n' '- none'
  fi
}
