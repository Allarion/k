#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
K_BIN="${ROOT_DIR}/bin/k"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

log_step() {
  printf '  -> %s\n' "$*"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

run_test() {
  local name="$1"
  shift
  printf 'TEST: %s\n' "$name"
  "$@"
}

test_help_and_completion_without_repo() {
  local temp_home output
  temp_home="$(mktemp -d)"
  log_step "temporary HOME: $temp_home"

  HOME="$temp_home" output="$("$K_BIN" help)"
  printf '%s\n' "$output"
  assert_contains "$output" "k completion bash"
  assert_contains "$output" "k help todo"

  HOME="$temp_home" output="$("$K_BIN" help todo)"
  printf '%s\n' "$output"
  assert_contains "$output" "Manages scope-based todos"
  assert_contains "$output" "k todo add"

  HOME="$temp_home" output="$("$K_BIN" completion bash)"
  printf '%s\n' "$output"
  assert_contains "$output" "_k_completion()"
  assert_contains "$output" "complete -F _k_completion k"

  rm -rf "$temp_home"
}

test_repo_workflow_and_dynamic_completion() {
  local temp_home setup_output scope_output todo_add_output todo_start_output todo_list completion_output done_output config_file
  temp_home="$(mktemp -d)"
  log_step "temporary HOME: $temp_home"

  setup_output="$(HOME="$temp_home" "$K_BIN" setup 2>&1 <<'EOF'
Y

ci-host
work/project1-work
EOF
)"
  printf '%s\n' "$setup_output"
  assert_contains "$setup_output" "Setup complete"

  config_file="$temp_home/.k/.knowledge/config"
  log_step "disable git auto commit in $config_file"
  sed -i 's/^GIT_AUTO_COMMIT="true"/GIT_AUTO_COMMIT="false"/' "$config_file"

  scope_output="$(HOME="$temp_home" "$K_BIN" scope use common/git)"
  printf '%s\n' "$scope_output"
  assert_contains "$scope_output" "Active scope: common/git"

  log_step "verify repo-level scopes and tags files"
  [[ -f "$temp_home/.k/repo/scopes.txt" ]] || fail "expected scopes.txt in repo"
  [[ -f "$temp_home/.k/repo/tags.txt" ]] || fail "expected tags.txt in repo"
  [[ ! -f "$temp_home/.k/.knowledge/scopes.txt" ]] || fail "scopes.txt should not live in .knowledge"
  [[ ! -f "$temp_home/.k/.knowledge/tags.txt" ]] || fail "tags.txt should not live in .knowledge"

  todo_add_output="$(HOME="$temp_home" "$K_BIN" todo add "Investigate completion bug")"
  printf '%s\n' "$todo_add_output"
  todo_start_output="$(HOME="$temp_home" "$K_BIN" todo start)"
  printf '%s\n' "$todo_start_output"
  done_output="$(HOME="$temp_home" "$K_BIN" todo done)"
  printf '%s\n' "$done_output"
  assert_contains "$done_output" "Done in common/git: Investigate completion bug"

  todo_list="$(HOME="$temp_home" "$K_BIN" todo list)"
  printf '%s\n' "$todo_list"
  assert_contains "$todo_list" "## Done"
  assert_contains "$todo_list" "Investigate completion bug"

  completion_output="$(HOME="$temp_home" "$K_BIN" __complete scope use --scope)"
  printf '%s\n' "$completion_output"
  assert_contains "$completion_output" "common/git"
  assert_contains "$completion_output" "work/project1-work"

  rm -rf "$temp_home"
}

main() {
  run_test "help and completion without repo" test_help_and_completion_without_repo
  run_test "repo workflow and dynamic completion" test_repo_workflow_and_dynamic_completion
  printf 'All tests passed\n'
}

main "$@"
