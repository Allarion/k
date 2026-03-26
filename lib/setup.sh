#!/usr/bin/env bash

k_setup_default_repo_path() {
  printf '%s/.k/repo
' "$HOME"
}

k_setup_run() {
  local target="${1:-$(k_setup_default_repo_path)}"
  target="${target/#\~/$HOME}"

  local anchor_dir repo_dir knowledge_dir scopes_file tags_file config_file current_scope_file
  repo_dir="$target"
  anchor_dir="$(dirname "$repo_dir")"
  knowledge_dir="$repo_dir/.knowledge"
  scopes_file="$knowledge_dir/scopes.txt"
  tags_file="$knowledge_dir/tags.txt"
  config_file="$knowledge_dir/config"
  current_scope_file="$knowledge_dir/current_scope"

  k_info "Starting knowledge repository setup"
  k_vinfo 1 "Host anchor directory: $anchor_dir"
  k_vinfo 1 "Target repository path: $repo_dir"
  k_vinfo 2 "Tool root: $(k_tool_root)"

  mkdir -p "$repo_dir"
  k_vinfo 2 "Ensured directory exists: $repo_dir"

  if [[ -d "$repo_dir/.git" ]]; then
    k_info "Git repository already present"
    k_vinfo 2 "Using existing git repository: $repo_dir/.git"
  else
    local init_git="Y"
    printf 'Initialize git repository in %s? [Y/n] ' "$repo_dir"
    IFS= read -r init_git
    init_git="${init_git:-Y}"
    if [[ "$init_git" =~ ^[Yy]$ ]]; then
      k_vinfo 1 "Initializing git repository"
      k_git_init_repo "$repo_dir"
      k_info "Initialized git repository"
    else
      k_warn "Continuing without git initialization"
    fi
  fi

  local origin_url
  if [[ -d "$repo_dir/.git" ]]; then
    if git -C "$repo_dir" remote get-url origin >/dev/null 2>&1; then
      k_vinfo 1 "Origin remote already configured"
      k_vinfo 2 "Existing origin: $(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    else
      printf 'Origin remote URL [optional]: '
      IFS= read -r origin_url
      if [[ -n "$origin_url" ]]; then
        git -C "$repo_dir" remote add origin "$origin_url"
        k_info "Configured git remote: origin"
        k_vinfo 2 "Origin URL: $origin_url"
      fi
    fi
  else
    k_vinfo 1 "Skipping origin remote setup without git repository"
  fi

  k_vinfo 1 "Creating directory structure"
  mkdir -p     "$knowledge_dir/templates"     "$repo_dir/journal"     "$repo_dir/drafts"     "$repo_dir/todos"     "$repo_dir/entries/problem"     "$repo_dir/entries/solution"     "$repo_dir/entries/insight"     "$repo_dir/entries/decision"     "$repo_dir/entries/idea"     "$repo_dir/entries/project"

  k_vinfo 2 "Knowledge metadata dir: $knowledge_dir"
  k_vinfo 2 "Entries dir: $repo_dir/entries"
  k_vinfo 2 "Journal dir: $repo_dir/journal"
  k_vinfo 2 "Todos dir: $repo_dir/todos"
  k_vinfo 2 "Drafts dir: $repo_dir/drafts"

  if [[ ! -f "$config_file" ]]; then
    k_vinfo 1 "Writing default config"
    cat > "$config_file" <<'EOF_CONFIG'
DEVICE=""
EDITOR_CMD="${EDITOR:-nano}"
DEFAULT_SCOPE=""
GIT_AUTO_COMMIT="true"
EOF_CONFIG
  else
    k_vinfo 1 "Keeping existing config"
  fi

  if [[ ! -f "$scopes_file" ]]; then
    k_vinfo 1 "Writing default scopes"
    cat > "$scopes_file" <<'EOF_SCOPES'
private/arx
private/auxion
private/printer
work/bgprevent
common/git
common/traefik
EOF_SCOPES
  else
    k_vinfo 1 "Keeping existing scopes file"
  fi

  if [[ ! -f "$tags_file" ]]; then
    k_vinfo 1 "Writing default tags"
    cat > "$tags_file" <<'EOF_TAGS'
infra
traefik
auth
java
quarkus
outbox
git
printer
linux
bash
EOF_TAGS
  else
    k_vinfo 1 "Keeping existing tags file"
  fi

  if [[ ! -f "$current_scope_file" ]]; then
    k_clear_file "$current_scope_file"
    k_vinfo 2 "Created current scope file"
  fi

  k_vinfo 1 "Installing default templates"
  cp -n "$(k_tool_root)/templates/"*.md "$knowledge_dir/templates/"
  k_vinfo 2 "Templates target: $knowledge_dir/templates"

  local env_default env_name
  env_default="$(hostname -s 2>/dev/null || hostname || printf 'unknown-host')"
  printf 'Environment name [%s]: ' "$env_default"
  IFS= read -r env_name
  env_name="${env_name:-$env_default}"
  k_config_set_in_file "$config_file" "DEVICE" "$env_name"
  k_vinfo 1 "Configured environment name: $env_name"

  local default_scope
  printf 'Default scope [optional]: '
  IFS= read -r default_scope
  if [[ -n "$default_scope" ]]; then
    k_config_set_in_file "$config_file" "DEFAULT_SCOPE" "$default_scope"
    k_current_scope_set_in_file "$current_scope_file" "$default_scope"
    k_vinfo 1 "Configured default scope: $default_scope"
  else
    k_config_set_in_file "$config_file" "DEFAULT_SCOPE" ""
  fi

  k_info "Setup complete"
  k_info "Repository: $repo_dir"
  k_info "Environment: $env_name"
  if [[ -n "$default_scope" ]]; then
    k_info "Default scope: $default_scope"
  fi
  k_info "Next: cd $repo_dir && k scope use <domain/system>"
}
