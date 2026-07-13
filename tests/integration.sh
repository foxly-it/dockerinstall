#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1; pwd)"
SCRIPT="$REPO_DIR/dockerinstall.sh"
MOCK_SOURCE="$REPO_DIR/tests/mock-command.sh"
TEST_DIR="$(mktemp -d)"
MOCK_BIN="$TEST_DIR/bin"
MOCK_LOG="$TEST_DIR/commands.log"

cleanup() {
  if [ "${KEEP_TEST_DIR:-0}" = "1" ]; then
    printf 'Test directory retained: %s\n' "$TEST_DIR" >&2
  else
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "Expected file: $1"
}

assert_contains() {
  grep -Fq "$2" "$1" || fail "Expected '$2' in $1"
}

assert_not_contains() {
  if grep -Fq "$2" "$1"; then
    fail "Did not expect '$2' in $1"
  fi
}

make_mocks() {
  mkdir -p "$MOCK_BIN"
  local command
  for command in apt-get curl dpkg dpkg-query systemctl docker usermod; do
    ln -s "$MOCK_SOURCE" "$MOCK_BIN/$command"
  done
  : > "$MOCK_LOG"
}

make_root() {
  local root="$1" id="$2" version="$3" codename="$4"
  mkdir -p "$root/etc/apt/sources.list.d" "$root/etc/apt/keyrings" \
    "$root/etc/docker" "$root/var/lib/docker" "$root/var/lib/containerd" \
    "$root/var/log" "$root/var/backups"
  printf 'ID=%s\nVERSION_ID="%s"\nVERSION_CODENAME=%s\n' \
    "$id" "$version" "$codename" > "$root/etc/os-release"
  printf '%s\n' 'legacy' > "$root/etc/apt/sources.list.d/docker.list"
  printf '%s\n' 'legacy-key' > "$root/etc/apt/keyrings/docker.gpg"
}

run_script() {
  local root="$1"
  shift
  DOCKERINSTALL_TEST_MODE=1 \
  DOCKERINSTALL_ROOT="$root" \
  DOCKERINSTALL_BACKUP_DIR="$root/var/backups" \
  MOCK_LOG="$MOCK_LOG" \
  PATH="$MOCK_BIN:$PATH" \
    "$SCRIPT" "$@" --no-clear --no-color
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "Command unexpectedly succeeded: $*"
  fi
}

test_cli_validation() {
  expect_failure "$SCRIPT" install --unknown-option
  expect_failure "$SCRIPT" install upgrade
  expect_failure "$SCRIPT" uninstall --remove-data --keep-data
  expect_failure "$SCRIPT" install --add-user
  expect_failure "$SCRIPT" install --backup-data
  expect_failure "$SCRIPT" upgrade --add-user nobody
  [ "$($SCRIPT --version)" = "2.1.0" ] || fail 'Unexpected version output'
}

test_supported_os_matrix() {
  local specification id version codename root
  for specification in \
    'debian 11 bullseye' \
    'debian 12 bookworm' \
    'debian 13 trixie' \
    'ubuntu 22.04 jammy' \
    'ubuntu 24.04 noble' \
    'ubuntu 25.10 questing' \
    'ubuntu 26.04 resolute'; do
    # Fields are controlled test data and intentionally split on spaces.
    # shellcheck disable=SC2086
    set -- $specification
    id="$1" version="$2" codename="$3"
    root="$TEST_DIR/matrix-${id}-${version}"
    make_root "$root" "$id" "$version" "$codename"
    run_script "$root" --self-check
  done

  root="$TEST_DIR/unsupported"
  make_root "$root" debian 10 buster
  expect_failure run_script "$root" --self-check
}

test_debian_install() {
  local root="$TEST_DIR/debian"
  make_root "$root" debian 13 trixie
  run_script "$root" install --non-interactive

  assert_file "$root/etc/apt/sources.list.d/docker.sources"
  assert_file "$root/etc/apt/keyrings/docker.asc"
  [ ! -e "$root/etc/apt/sources.list.d/docker.list" ] || fail 'Legacy source was not removed'
  [ ! -e "$root/etc/apt/keyrings/docker.gpg" ] || fail 'Legacy key was not removed'
  assert_contains "$root/etc/apt/sources.list.d/docker.sources" 'URIs: https://download.docker.com/linux/debian'
  assert_contains "$root/etc/apt/sources.list.d/docker.sources" 'Suites: trixie'
  assert_contains "$MOCK_LOG" 'apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'
  assert_contains "$MOCK_LOG" 'docker run --rm hello-world'
}

test_ubuntu_install_and_user_argument() {
  local root="$TEST_DIR/ubuntu"
  local current_user
  current_user="$(id -un)"
  make_root "$root" ubuntu 24.04 noble
  run_script "$root" install --non-interactive --no-hello --add-user "$current_user"

  assert_contains "$root/etc/apt/sources.list.d/docker.sources" 'URIs: https://download.docker.com/linux/ubuntu'
  assert_contains "$root/etc/apt/sources.list.d/docker.sources" 'Suites: noble'
  assert_contains "$MOCK_LOG" "usermod -aG docker $current_user"
  assert_not_contains "$MOCK_LOG" 'docker run --rm hello-world'
}

test_upgrade_backup_and_force() {
  local root="$TEST_DIR/upgrade"
  make_root "$root" debian 12 bookworm
  printf '%s\n' data > "$root/var/lib/docker/marker"
  run_script "$root" upgrade --backup-data --force-upgrade --non-interactive --no-hello

  find "$root/var/backups" -name 'docker-backup-*.tar.gz' -type f | grep -q . || \
    fail 'Backup archive was not created'
  assert_contains "$MOCK_LOG" 'systemctl stop docker.service docker.socket containerd.service'
  assert_contains "$MOCK_LOG" 'apt-get install -y --reinstall docker-ce'
}

test_uninstall_data_safety() {
  local keep_root="$TEST_DIR/uninstall-keep"
  local remove_root="$TEST_DIR/uninstall-remove"
  make_root "$keep_root" debian 13 trixie
  printf '%s\n' keep > "$keep_root/var/lib/docker/marker"
  MOCK_INSTALLED_PACKAGES='docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras' \
    run_script "$keep_root" uninstall --non-interactive
  assert_file "$keep_root/var/lib/docker/marker"
  assert_contains "$MOCK_LOG" 'docker-ce-rootless-extras'

  make_root "$remove_root" debian 13 trixie
  printf '%s\n' remove > "$remove_root/var/lib/docker/marker"
  run_script "$remove_root" uninstall --remove-data --non-interactive
  [ ! -e "$remove_root/var/lib/docker" ] || fail 'Docker data was not removed explicitly'
}

make_mocks
test_cli_validation
test_supported_os_matrix
test_debian_install
: > "$MOCK_LOG"
test_ubuntu_install_and_user_argument
: > "$MOCK_LOG"
test_upgrade_backup_and_force
: > "$MOCK_LOG"
test_uninstall_data_safety

printf '%s\n' 'All integration tests passed.'
