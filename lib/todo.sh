#!/usr/bin/env bash

k_todo_file_for_scope() {
  local scope="$1"
  printf '%s/%s\n' "$(k_todos_dir)" "$(k_scope_to_todo_filename "$scope")"
}

k_todo_ensure_file() {
  local scope="$1"
  local file
  file="$(k_todo_file_for_scope "$scope")"
  if [[ ! -f "$file" ]]; then
    mkdir -p "$(dirname "$file")"
    cat > "$file" <<EOF2
---
scope: $scope
updated: $(k_timestamp_iso)
---

# Todos: $scope

## Open

## In Progress

## Done
EOF2
  fi
  printf '%s\n' "$file"
}

k_todo_add() {
  local scope="$1"
  local title="$2"
  local priority="$3"
  local tags_csv="$4"
  local file tmp id tags_line
  file="$(k_todo_ensure_file "$scope")"
  tmp="${file}.tmp"
  id="todo-$(k_today)-$(k_time_compact)-$(k_slugify "$title")"
  tags_line="$(k_tags_bracketed "$tags_csv")"

  awk -v title="$title" -v id="$id" -v priority="$priority" -v tags="$tags_line" -v created="$(k_timestamp_iso)" '
    {
      print $0
      if ($0 == "## Open") {
        print "- [ ] " title
        print "  - id: " id
        print "  - tags: " tags
        print "  - priority: " priority
        print "  - created: " created
      }
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"

  printf '%s\n' "$title"
}

k_todo_list() {
  local scope="$1"
  local file
  file="$(k_todo_ensure_file "$scope")"
  cat "$file"
}

k_todo_open_titles() {
  local scope="$1"
  local file
  file="$(k_todo_ensure_file "$scope")"
  awk '
    /^## In Progress/ {exit}
    /^- \[ \]/ {sub(/^- \[ \] /, ""); print}
  ' "$file"
}

k_todo_done_by_index() {
  local scope="$1"
  local index="$2"
  local file tmp title
  file="$(k_todo_ensure_file "$scope")"
  tmp="${file}.tmp"
  title="$(awk -v idx="$index" '
    BEGIN {count=0}
    /^## In Progress/ {exit}
    /^- \[ \]/ {count++; if (count == idx) {sub(/^- \[ \] /, ""); print; exit}}
  ' "$file")"
  [[ -n "$title" ]] || k_die "Todo index not found: $index" 4

  awk -v idx="$index" '
    BEGIN {count=0; skip_meta=0}
    {
      if ($0 ~ /^## In Progress/) {
        in_open=0
      }
      if ($0 ~ /^## Open/) {
        in_open=1
        print $0
        next
      }
      if (in_open && $0 ~ /^- \[ \]/) {
        count++
        if (count == idx) {skip_meta=1; next}
      }
      if (skip_meta) {
        if ($0 ~ /^  - /) {next}
        skip_meta=0
      }
      print $0
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"

  printf '\n## Done\n- [x] %s\n' "$title" >> "$file"
  printf '%s\n' "$title"
}
