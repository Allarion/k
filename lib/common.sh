#!/usr/bin/env bash

k_verbose=0

k_set_verbosity() {
  k_verbose="${1:-0}"
}

k_vinfo() {
  local level="${1:-1}"
  shift || true
  if (( k_verbose >= level )); then
    printf '[V%d] %s\n' "$level" "$*" >&2
  fi
}

k_log() { printf '%s\n' "$*" >&2; }
k_info() { printf '[INFO] %s\n' "$*" >&2; }
k_warn() { printf '[WARN] %s\n' "$*" >&2; }
k_error() { printf '[ERROR] %s\n' "$*" >&2; }

k_die() {
  local message="${1:-unknown error}"
  local code="${2:-1}"
  k_error "$message"
  exit "$code"
}

k_require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || k_die "Required command not found: $cmd"
}

k_timestamp_iso() { date --iso-8601=seconds; }
k_today() { date +%F; }
k_year() { date +%Y; }
k_time_hhmm() { date +%H:%M; }
k_time_compact() { date +%H%M; }

k_slugify() {
  local input="${1:-}"
  printf '%s' "$input" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
  printf '\n'
}

k_tool_root() {
  printf '%s\n' "$K_TOOL_ROOT"
}

k_default_repo_root() {
  local path
  path="$(k_setup_default_repo_path)"
  path="${path/#\~/$HOME}"
  printf '%s\n' "$path"
}

k_repo_exists() {
  local repo_root
  repo_root="$(k_default_repo_root)"
  [[ -d "$repo_root/.knowledge" ]]
}

k_repo_root() {
  local root
  root="$(k_default_repo_root)"
  [[ -d "$root/.knowledge" ]] || k_die "Knowledge repo not found at $root. Run 'k setup' first." 1
  printf '%s\n' "$root"
}

k_has_repo() { k_repo_exists; }

k_knowledge_dir() { printf '%s/.knowledge\n' "$(k_repo_root)"; }
k_config_file() { printf '%s/config\n' "$(k_knowledge_dir)"; }
k_current_scope_file() { printf '%s/current_scope\n' "$(k_knowledge_dir)"; }
k_scopes_file() { printf '%s/scopes.txt\n' "$(k_knowledge_dir)"; }
k_tags_file() { printf '%s/tags.txt\n' "$(k_knowledge_dir)"; }
k_templates_dir() { printf '%s/templates\n' "$(k_knowledge_dir)"; }
k_journal_dir() { printf '%s/journal\n' "$(k_repo_root)"; }
k_entries_dir() { printf '%s/entries\n' "$(k_repo_root)"; }
k_drafts_dir() { printf '%s/drafts\n' "$(k_repo_root)"; }
k_todos_dir() { printf '%s/todos\n' "$(k_repo_root)"; }

k_journal_file_for_date() {
  local d="${1:-$(k_today)}"
  local year="${d%%-*}"
  printf '%s/%s/%s.md\n' "$(k_journal_dir)" "$year" "$d"
}

k_ensure_dir() { mkdir -p "$1"; }

k_ensure_file() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  [[ -f "$file" ]] || : > "$file"
}

k_read_first_line() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  local line
  IFS= read -r line < "$file" || true
  printf '%s\n' "${line:-}"
}

k_write_file() {
  local file="$1"
  shift
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$*" > "$file"
}

k_clear_file() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  : > "$file"
}

k_escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

k_config_set_in_file() {
  local config_file="$1"
  local key="$2"
  local value="${3:-}"
  mkdir -p "$(dirname "$config_file")"
  [[ -f "$config_file" ]] || : > "$config_file"

  if grep -Eq "^${key}=" "$config_file"; then
    sed -i "s/^${key}=.*/${key}=\"$(k_escape_sed_replacement "$value")\"/" "$config_file"
  else
    printf '%s="%s"\n' "$key" "$value" >> "$config_file"
  fi
}

k_config_set() {
  local key="$1"
  local value="${2:-}"
  k_config_set_in_file "$(k_config_file)" "$key" "$value"
}

k_current_scope_set_in_file() {
  local current_scope_file="$1"
  local scope="$2"
  k_write_file "$current_scope_file" "$scope"
}

k_current_scope_set() {
  local scope="$1"
  k_current_scope_set_in_file "$(k_current_scope_file)" "$scope"
}

k_current_scope_clear() {
  k_clear_file "$(k_current_scope_file)"
}

k_append_line() {
  local file="$1"
  shift
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$*" >> "$file"
}

k_normalize_tags() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || return 0
  printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | tr ',' '\n' \
    | sed -E 's/^ +//; s/ +$//' \
    | sed '/^$/d' \
    | awk '!seen[$0]++' \
    | paste -sd, -
}

k_tags_bracketed() {
  local raw="$(k_normalize_tags "${1:-}")"
  if [[ -z "$raw" ]]; then
    printf '[]\n'
  else
    printf '[%s]\n' "$(printf '%s' "$raw" | sed 's/,/, /g')"
  fi
}

k_tags_csv_to_journal_token() {
  local raw="$(k_normalize_tags "${1:-}")"
  [[ -n "$raw" ]] || return 0
  printf '[tags:%s]\n' "$raw"
}

k_load_config() {
  K_DEVICE=""
  K_EDITOR_CMD="${EDITOR:-nano}"
  K_DEFAULT_SCOPE=""
  K_GIT_AUTO_COMMIT="true"

  local config
  if k_has_repo; then
    config="$(k_config_file)"
    if [[ -f "$config" ]]; then
      # shellcheck disable=SC1090
      source "$config"
    fi
  fi

  K_DEVICE="${DEVICE:-${K_DEVICE}}"
  K_EDITOR_CMD="${EDITOR_CMD:-${K_EDITOR_CMD}}"
  K_DEFAULT_SCOPE="${DEFAULT_SCOPE:-${K_DEFAULT_SCOPE}}"
  K_GIT_AUTO_COMMIT="${GIT_AUTO_COMMIT:-${K_GIT_AUTO_COMMIT}}"
}

k_get_current_scope() {
  local scope_file scope
  if k_has_repo; then
    scope_file="$(k_current_scope_file)"
    if [[ -f "$scope_file" ]]; then
      scope="$(k_read_first_line "$scope_file")"
      if [[ -n "$scope" ]]; then
        printf '%s\n' "$scope"
        return 0
      fi
    fi
  fi
  k_load_config
  if [[ -n "$K_DEFAULT_SCOPE" ]]; then
    printf '%s\n' "$K_DEFAULT_SCOPE"
    return 0
  fi
  return 1
}

k_require_scope() {
  local scope
  scope="$(k_get_current_scope)" || k_die "No active scope set. Use: k scope use <domain/system>" 3
  printf '%s\n' "$scope"
}

k_scope_to_todo_filename() {
  local scope="${1:?scope required}"
  printf '%s\n' "${scope//\//-}.md"
}

k_open_editor() {
  local file="$1"
  k_load_config
  eval "$K_EDITOR_CMD \"$file\""
}

k_find_latest_file() {
  local dir="$1"
  [[ -d "$dir" ]] || return 1
  find "$dir" -maxdepth 1 -type f -name '*.md' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-
}
