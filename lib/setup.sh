#!/usr/bin/env bash

k_setup_run() {
  local target="${1:-.}"
  mkdir -p "$target"

  if [[ ! -d "$target/.git" ]]; then
    read -r -p "Git-Repository initialisieren? [Y/n] " answer
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      k_git_init_repo "$target"
      k_info "Initialized git repository"
    fi
  fi

  mkdir -p "$target/.knowledge/templates" "$target/journal" "$target/entries" "$target/drafts" "$target/todos"
  mkdir -p "$target/entries"/{problem,solution,insight,decision,idea,project}

  [[ -f "$target/.knowledge/config" ]] || cat > "$target/.knowledge/config" <<'EOF2'
DEVICE=""
EDITOR_CMD="${EDITOR:-nano}"
DEFAULT_SCOPE=""
GIT_AUTO_COMMIT="true"
EOF2

  [[ -f "$target/.knowledge/scopes.txt" ]] || cat > "$target/.knowledge/scopes.txt" <<'EOF2'
private/arx
private/auxion
work/bgprevent
shared/git
EOF2

  [[ -f "$target/.knowledge/tags.txt" ]] || cat > "$target/.knowledge/tags.txt" <<'EOF2'
infra
traefik
auth
java
quarkus
outbox
git
EOF2

  : > "$target/.knowledge/current_scope"

  cp -n "$(k_tool_root)/templates/"*.md "$target/.knowledge/templates/"

  read -r -p "Wie heißt diese Umgebung? [$(hostname -s)] " env_name
  env_name="${env_name:-$(hostname -s)}"
  sed -i "s/^DEVICE=.*/DEVICE=\"$env_name\"/" "$target/.knowledge/config"

  k_info "Setup complete in: $target"
  k_info "Next: cd $target && k scope use <domain/system>"
}
