#!/usr/bin/env bash

k_todo_file_for_scope() {
  local scope="$1"
  printf '%s/%s\n' "$(k_todos_dir)" "$(k_scope_to_todo_filename "$scope")"
}

k_todo_section_marker() {
  case "$1" in
    open) printf ' ' ;;
    progress) printf '~' ;;
    done) printf 'x' ;;
    *) return 1 ;;
  esac
}

k_todo_normalize_index() {
  local index="${1:-0}"
  if [[ -z "$index" || "$index" == "0" ]]; then
    printf '1\n'
  else
    printf '%s\n' "$index"
  fi
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
  k_todo_section_titles "$scope" open
}

k_todo_progress_titles() {
  local scope="$1"
  k_todo_section_titles "$scope" progress
}

k_todo_done_titles() {
  local scope="$1"
  k_todo_section_titles "$scope" done
}

k_todo_section_titles() {
  local scope="$1"
  local section="$2"
  local file
  file="$(k_todo_ensure_file "$scope")"
  awk -v wanted="$section" '
    function section_name(line) {
      if (line == "## Open") return "open"
      if (line == "## In Progress") return "progress"
      if (line == "## Done") return "done"
      return ""
    }
    /^## / {current=section_name($0); next}
    current == wanted && /^- \[[^]]+\] / {
      sub(/^- \[[^]]+\] /, "")
      print
    }
  ' "$file"
}

k_todo_section_count() {
  local scope="$1"
  local section="$2"
  local file
  file="$(k_todo_ensure_file "$scope")"
  awk -v wanted="$section" '
    function section_name(line) {
      if (line == "## Open") return "open"
      if (line == "## In Progress") return "progress"
      if (line == "## Done") return "done"
      return ""
    }
    /^## / {current=section_name($0); next}
    current == wanted && /^- \[[^]]+\] / {count++}
    END {print count + 0}
  ' "$file"
}

k_todo_status_summary() {
  local scope="$1"
  printf 'Open: %s, In Progress: %s, Done: %s\n' \
    "$(k_todo_section_count "$scope" open)" \
    "$(k_todo_section_count "$scope" progress)" \
    "$(k_todo_section_count "$scope" done)"
}

k_todo_move_by_index() {
  local scope="$1"
  local source_section="$2"
  local target_section="$3"
  local raw_index="${4:-0}"
  local file tmp title index target_marker
  file="$(k_todo_ensure_file "$scope")"
  tmp="${file}.tmp"
  index="$(k_todo_normalize_index "$raw_index")"
  target_marker="$(k_todo_section_marker "$target_section")"

  title="$(awk -v wanted="$source_section" -v idx="$index" '
    function section_name(line) {
      if (line == "## Open") return "open"
      if (line == "## In Progress") return "progress"
      if (line == "## Done") return "done"
      return ""
    }
    /^## / {current=section_name($0); next}
    current == wanted && /^- \[[^]]+\] / {
      count++
      if (count == idx) {
        sub(/^- \[[^]]+\] /, "")
        print
        exit
      }
    }
  ' "$file")"
  [[ -n "$title" ]] || k_die "Todo index not found in ${source_section}: ${raw_index:-0}" 4

  awk -v src="$source_section" -v dst="$target_section" -v idx="$index" -v dst_mark="$target_marker" '
    function section_name(line) {
      if (line == "## Open") return "open"
      if (line == "## In Progress") return "progress"
      if (line == "## Done") return "done"
      return ""
    }
    function flush_item(sec) {
      if (item == "") return
      section_count[sec]++
      section_items[sec, section_count[sec]] = item
      item = ""
    }
    {
      if ($0 ~ /^## /) {
        if (current == "") {
          preamble = preamble item
        } else {
          flush_item(current)
        }
        item = ""
        current = section_name($0)
        headings[current] = $0
        next
      }

      if (current == "") {
        preamble = preamble $0 ORS
        next
      }

      if ($0 ~ /^- \[[^]]+\] /) {
        flush_item(current)
        item = $0 ORS
        next
      }

      if (item != "") {
        item = item $0 ORS
      } else {
        section_body[current] = section_body[current] $0 ORS
      }
    }
    END {
      if (current != "") {
        flush_item(current)
      }

      moved = ""
      kept = 0
      for (i = 1; i <= section_count[src]; i++) {
        if (i == idx) {
          moved = section_items[src, i]
        } else {
          kept++
          new_items[src, kept] = section_items[src, i]
        }
      }
      section_count[src] = kept

      if (moved != "") {
        sub(/^- \[[^]]+\]/, "- [" dst_mark "]", moved)
        for (i = section_count[dst]; i >= 1; i--) {
          new_items[dst, i + 1] = section_items[dst, i]
        }
        new_items[dst, 1] = moved
        section_count[dst]++
      }

      printf "%s", preamble
      order[1] = "open"
      order[2] = "progress"
      order[3] = "done"
      for (o = 1; o <= 3; o++) {
        sec = order[o]
        print headings[sec]
        if (section_body[sec] != "") {
          printf "%s", section_body[sec]
        }
        for (i = 1; i <= section_count[sec]; i++) {
          if (new_items[sec, i] != "") {
            printf "%s", new_items[sec, i]
          } else if (section_items[sec, i] != "") {
            printf "%s", section_items[sec, i]
          }
        }
        if (o < 3) print ""
      }
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"

  printf '%s\n' "$title"
}

k_todo_done_by_index() {
  local scope="$1"
  local index="${2:-0}"
  if [[ "$(k_todo_section_count "$scope" progress)" -gt 0 ]]; then
    k_todo_move_by_index "$scope" progress done "$index"
  else
    k_todo_move_by_index "$scope" open done "$index"
  fi
}

k_todo_start_by_index() {
  local scope="$1"
  local index="${2:-0}"
  k_todo_move_by_index "$scope" open progress "$index"
}

k_todo_reopen_by_index() {
  local scope="$1"
  local index="${2:-0}"
  k_todo_move_by_index "$scope" done open "$index"
}
