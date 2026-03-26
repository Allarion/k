#!/usr/bin/env bash

k_valid_entry_type() {
  case "$1" in
    problem|solution|insight|decision|idea|project) return 0 ;;
    *) return 1 ;;
  esac
}

k_entry_create_draft() {
  local type="$1"
  local title="$2"
  local scope="$3"
  local tags_csv="$4"

  k_valid_entry_type "$type" || k_die "Invalid entry type: $type" 2

  local ts date_part time_part slug id header_t body_t draft_file created updated
  date_part="$(k_today)"
  time_part="$(k_time_compact)"
  slug="$(k_slugify "$title")"
  id="${date_part}-${time_part}-${slug}"
  created="$(k_timestamp_iso)"
  updated="$created"
  header_t="$(k_templates_dir)/header.md"
  body_t="$(k_templates_dir)/${type}.md"
  draft_file="$(k_drafts_dir)/${id}.md"

  mkdir -p "$(k_drafts_dir)"

  {
    k_render_template "$header_t" "$id" "$type" "$title" "$scope" "$tags_csv" "$created" "$updated" "draft"
    printf '\n'
    k_render_template "$body_t" "$id" "$type" "$title" "$scope" "$tags_csv" "$created" "$updated" "draft"
    printf '\n'
  } > "$draft_file"

  printf '%s\n' "$draft_file"
}

k_entry_find_latest_draft() {
  k_find_latest_file "$(k_drafts_dir)"
}

k_entry_list_drafts() {
  if [[ -d "$(k_drafts_dir)" ]]; then
    find "$(k_drafts_dir)" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort -r
  fi
}

k_entry_list_scope_drafts() {
  local scope="$1"
  local file dscope
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    dscope="$(k_entry_frontmatter_get "$file" scope 2>/dev/null || true)"
    if [[ -z "$scope" || "$dscope" == "$scope" ]]; then
      printf '%s\n' "$file"
    fi
  done < <(k_entry_list_drafts)
}

k_entry_frontmatter_get() {
  local file="$1"
  local key="$2"
  awk -F': ' -v key="$key" '
    BEGIN {in_fm=0}
    /^---$/ { if (!in_fm) {in_fm=1; next} else {exit} }
    in_fm && $1 == key {print substr($0, index($0, ":") + 2); exit}
  ' "$file"
}

k_entry_frontmatter_replace() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp
  tmp="${file}.tmp"
  awk -v key="$key" -v value="$value" '
    BEGIN {in_fm=0}
    /^---$/ {
      print
      if (!in_fm) {in_fm=1; next} else {exit_fm=1; next}
    }
    in_fm && !exit_fm {
      if ($0 ~ "^" key ":") {$0 = key ": " value}
      print
      next
    }
    {print}
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

k_entry_finalize_draft() {
  local file="$1"
  local extra_tags_csv="$2"
  [[ -f "$file" ]] || k_die "Draft not found: $file" 4

  local type title current_tags merged_tags updated status target_dir target_file
  type="$(k_entry_frontmatter_get "$file" type)"
  title="$(k_entry_frontmatter_get "$file" title)"
  current_tags="$(k_entry_frontmatter_get "$file" tags | sed -E 's/^\[//; s/\]$//; s/, /,/g')"
  merged_tags="$(k_normalize_tags "$current_tags,$extra_tags_csv")"
  updated="$(k_timestamp_iso)"

  k_entry_frontmatter_replace "$file" updated "$updated"
  k_entry_frontmatter_replace "$file" status "final"
  k_entry_frontmatter_replace "$file" tags "$(k_tags_bracketed "$merged_tags")"

  target_dir="$(k_entries_dir)/$type"
  mkdir -p "$target_dir"
  target_file="$target_dir/$(basename "$file")"
  mv "$file" "$target_file"

  printf '%s\n' "$target_file"
}

k_entry_latest_for_scope() {
  local scope="$1"
  local file
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    if [[ "$(k_entry_frontmatter_get "$file" scope 2>/dev/null || true)" == "$scope" ]]; then
      printf '%s\n' "$file"
      return 0
    fi
  done < <(find "$(k_entries_dir)" -type f -name '*.md' 2>/dev/null | sort -r)
  return 1
}
