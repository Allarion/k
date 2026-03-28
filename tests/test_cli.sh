#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
K_BIN="${ROOT_DIR}/bin/k"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
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
  HOME="$temp_home" output="$("$K_BIN" help)"
  assert_contains "$output" "k completion bash"
  assert_contains "$output" "k help todo"

  HOME="$temp_home" output="$("$K_BIN" help todo)"
  assert_contains "$output" "Manages scope-based todos"
  assert_contains "$output" "k todo add"

  HOME="$temp_home" output="$("$K_BIN" completion bash)"
  assert_contains "$output" "_k_completion()"
  assert_contains "$output" "complete -F _k_completion k"

  rm -rf "$temp_home"
}

test_repo_workflow_and_dynamic_completion() {
  local temp_home setup_output scope_output todo_list completion_output done_output config_file
  temp_home="$(mktemp -d)"

  setup_output="$(HOME="$temp_home" "$K_BIN" setup 2>&1 <<'EOF'
Y

ci-host
work/project1-work
EOF
)"
  assert_contains "$setup_output" "Setup complete"

  config_file="$temp_home/.k/.knowledge/config"
  sed -i 's/^GIT_AUTO_COMMIT="true"/GIT_AUTO_COMMIT="false"/' "$config_file"

  scope_output="$(HOME="$temp_home" "$K_BIN" scope use common/git)"
  assert_contains "$scope_output" "Active scope: common/git"

  HOME="$temp_home" "$K_BIN" todo add "Investigate completion bug" >/dev/null
  HOME="$temp_home" "$K_BIN" todo start >/dev/null
  done_output="$(HOME="$temp_home" "$K_BIN" todo done)"
  assert_contains "$done_output" "Done in common/git: Investigate completion bug"

  todo_list="$(HOME="$temp_home" "$K_BIN" todo list)"
  assert_contains "$todo_list" "## Done"
  assert_contains "$todo_list" "Investigate completion bug"

  completion_output="$(HOME="$temp_home" "$K_BIN" __complete scope use --scope)"
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
