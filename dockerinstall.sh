#!/usr/bin/env bash
# Foxly dockerinstall - Docker Engine lifecycle manager
# Supported: Debian 11/12/13 and Ubuntu 22.04/24.04/25.10/26.04
# Version: 2.1.0

set -Eeuo pipefail

VERSION="2.1.0"
ACTION=""
ADD_USER=""
HELLO=1
CLEAR=1
NON_INTERACTIVE=0
FORCE_UPGRADE=0
BACKUP_DATA=0
REMOVE_DATA=0
KEEP_DATA=0
NO_COLOR="${NO_COLOR:-0}"
LOG_FILE=""
LOG_FILE_EXPLICIT=0
TEST_MODE="${DOCKERINSTALL_TEST_MODE:-0}"
SYSTEM_ROOT="${DOCKERINSTALL_ROOT:-}"
BACKUP_DIR="${DOCKERINSTALL_BACKUP_DIR:-}"
PROG_ACTIVE=0

repo_file=""
key_file=""
OS_ID=""
OS_VERSION=""
OS_CODENAME=""

usage() {
  cat <<'EOF'
Foxly dockerinstall - install, upgrade, or uninstall Docker Engine

Usage:
  sudo ./dockerinstall.sh [install|upgrade|uninstall] [OPTIONS]
  sudo ./dockerinstall.sh --self-check

Options:
  --add-user=USER       Add USER to the docker group
  --add-user USER       Same as above
  --no-hello            Skip the hello-world verification
  --no-clear            Do not clear the terminal
  --no-color            Disable colored output
  --log-file=PATH       Write output to a custom log file
  --non-interactive     Never prompt for input
  --backup-data         Create a stopped, host-level Docker data backup
  --remove-data         Delete Docker data during uninstall
  --keep-data           Keep Docker data during uninstall (the default)
  --force-upgrade       Reinstall Docker packages even when already current
  --self-check          Validate the host without changing it
  -h, --help            Show this help
  --version             Show the script version

Data is never deleted unless --remove-data is supplied or deletion is
explicitly confirmed in interactive uninstall mode.
EOF
}

die() {
  log_err "$1"
  exit "${2:-1}"
}

system_path() {
  printf '%s%s' "$SYSTEM_ROOT" "$1"
}

is_tty() {
  [ -t 1 ]
}

init_colors() {
  if [ "$NO_COLOR" = "1" ] || ! is_tty; then
    C_RESET="" C_BOLD="" C_DIM="" C_INFO="" C_WARN="" C_ERR="" C_OK=""
  else
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_INFO=$'\033[38;5;45m'
    C_WARN=$'\033[38;5;214m'
    C_ERR=$'\033[38;5;196m'
    C_OK=$'\033[38;5;82m'
  fi
}

log_info() { printf '%s[INFO]%s %s\n' "$C_INFO" "$C_RESET" "$1"; }
log_warn() { printf '%s[WARN]%s %s\n' "$C_WARN" "$C_RESET" "$1"; }
log_err()  { printf '%s[FAIL]%s %s\n' "$C_ERR" "$C_RESET" "$1" >&2; }
log_ok()   { printf '%s[ OK ]%s %s\n' "$C_OK" "$C_RESET" "$1"; }

banner() {
  local mode="${1:-dockerinstall}"
  printf '\n%s%sFoxly dockerinstall%s %s- %s%s\n\n' \
    "$C_BOLD" "$C_INFO" "$C_RESET" "$C_DIM" "$mode" "$C_RESET"
}

progress_cleanup() {
  if [ "$PROG_ACTIVE" -eq 1 ]; then
    if is_tty; then
      printf '\n'
      tput cnorm 2>/dev/null || true
    fi
    PROG_ACTIVE=0
  fi
}

on_error() {
  local status line
  status="${1:-1}"
  line="${2:-unknown}"
  progress_cleanup
  log_err "Abbruch in Zeile ${line} (Exit ${status}). Siehe Logdatei für Details."
  exit "$status"
}

progress_init() {
  PROG_ACTIVE=1
  log_info "$1"
  if is_tty; then
    tput civis 2>/dev/null || true
  fi
}

progress_step() {
  log_info "$1"
}

progress_done() {
  progress_cleanup
  log_ok "$1"
}

set_action() {
  local requested="$1"
  if [ -n "$ACTION" ] && [ "$ACTION" != "$requested" ]; then
    die "Mehrere Aktionen angegeben: '$ACTION' und '$requested'."
  fi
  ACTION="$requested"
}

require_value() {
  local option="$1" value="${2:-}"
  [ -n "$value" ] || die "Option '$option' benötigt einen Wert."
  printf '%s' "$value"
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      install|upgrade|uninstall) set_action "$1" ;;
      --self-check) set_action "selfcheck" ;;
      --add-user=*) ADD_USER="$(require_value --add-user "${1#*=}")" ;;
      --add-user)
        [ "$#" -ge 2 ] || die "Option '--add-user' benötigt einen Wert."
        ADD_USER="$(require_value --add-user "$2")"
        shift
        ;;
      --no-hello) HELLO=0 ;;
      --no-clear) CLEAR=0 ;;
      --no-color) NO_COLOR=1 ;;
      --backup-data) BACKUP_DATA=1 ;;
      --remove-data) REMOVE_DATA=1 ;;
      --keep-data) KEEP_DATA=1 ;;
      --non-interactive) NON_INTERACTIVE=1 ;;
      --force-upgrade) FORCE_UPGRADE=1 ;;
      --log-file=*)
        LOG_FILE="$(require_value --log-file "${1#*=}")"
        LOG_FILE_EXPLICIT=1
        ;;
      -h|--help) usage; exit 0 ;;
      --version) printf '%s\n' "$VERSION"; exit 0 ;;
      --) shift; [ "$#" -eq 0 ] || die "Unerwartete Argumente: $*"; break ;;
      -*) die "Unbekannte Option: $1" ;;
      *) die "Unbekanntes Argument: $1" ;;
    esac
    shift
  done

  if [ "$REMOVE_DATA" -eq 1 ] && [ "$KEEP_DATA" -eq 1 ]; then
    die "--remove-data und --keep-data schließen sich gegenseitig aus."
  fi
  if [ "$ACTION" != "uninstall" ] && { [ "$REMOVE_DATA" -eq 1 ] || [ "$KEEP_DATA" -eq 1 ]; }; then
    die "--remove-data und --keep-data sind nur bei uninstall erlaubt."
  fi
  if [ "$FORCE_UPGRADE" -eq 1 ] && [ "$ACTION" != "upgrade" ]; then
    die "--force-upgrade ist nur bei upgrade erlaubt."
  fi
  if [ "$BACKUP_DATA" -eq 1 ] && [ "$ACTION" != "upgrade" ] && [ "$ACTION" != "uninstall" ]; then
    die "--backup-data ist nur bei upgrade oder uninstall erlaubt."
  fi
  if [ -n "$ADD_USER" ] && [ "$ACTION" != "install" ]; then
    die "--add-user ist nur bei install erlaubt."
  fi
}

show_menu_and_pick_action() {
  banner "Menü"
  printf '1) Docker installieren\n2) Docker aktualisieren\n9) Docker deinstallieren\n\nAuswahl: '
  local choice
  read -r choice
  case "$choice" in
    1) ACTION="install" ;;
    2) ACTION="upgrade" ;;
    9) ACTION="uninstall" ;;
    *) die "Ungültige Auswahl: $choice" ;;
  esac
}

require_root() {
  if [ "$TEST_MODE" != "1" ] && [ "$(id -u)" -ne 0 ]; then
    die "Dieses Skript muss mit root/sudo ausgeführt werden."
  fi
}

detect_os() {
  local os_release
  os_release="$(system_path /etc/os-release)"
  [ -r "$os_release" ] || die "Kann $os_release nicht lesen."

  ID="" VERSION_ID="" VERSION_CODENAME="" UBUNTU_CODENAME=""
  # /etc/os-release is a trusted, root-owned system file in normal operation.
  # shellcheck disable=SC1090
  . "$os_release"

  OS_ID="${ID:-}"
  OS_VERSION="${VERSION_ID:-}"
  if [ "$OS_ID" = "ubuntu" ]; then
    OS_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  else
    OS_CODENAME="${VERSION_CODENAME:-}"
  fi

  if [ -z "$OS_VERSION" ] || [ -z "$OS_CODENAME" ]; then
    die "Distribution oder Codename konnte nicht erkannt werden."
  fi

  case "${OS_ID}:${OS_VERSION}" in
    debian:11|debian:12|debian:13|ubuntu:22.04|ubuntu:24.04|ubuntu:25.10|ubuntu:26.04) ;;
    *) die "Nicht unterstütztes System: ${OS_ID} ${OS_VERSION} (${OS_CODENAME})." ;;
  esac

  repo_file="$(system_path /etc/apt/sources.list.d/docker.sources)"
  key_file="$(system_path /etc/apt/keyrings/docker.asc)"
}

require_commands() {
  local missing=() command
  for command in apt-get dpkg dpkg-query systemctl tee tar; do
    command -v "$command" >/dev/null 2>&1 || missing+=("$command")
  done
  [ "${#missing[@]}" -eq 0 ] || die "Fehlende Programme: ${missing[*]}"
}

check_apt_locks() {
  command -v fuser >/dev/null 2>&1 || return 0
  local lock
  for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock \
    /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
    if fuser "$(system_path "$lock")" >/dev/null 2>&1; then
      die "APT-Lock aktiv: $lock"
    fi
  done
}

validate_environment() {
  require_root
  detect_os
  require_commands
  check_apt_locks
  log_ok "Unterstütztes System: ${OS_ID} ${OS_VERSION} (${OS_CODENAME})"
}

configure_logging() {
  if [ "$LOG_FILE_EXPLICIT" -eq 0 ]; then
    case "$ACTION" in
      uninstall) LOG_FILE="$(system_path /var/log/docker-uninstall.log)" ;;
      selfcheck) LOG_FILE="$(system_path /var/log/docker-self-check.log)" ;;
      *) LOG_FILE="$(system_path /var/log/docker-install.log)" ;;
    esac
  fi
  mkdir -p "$(dirname "$LOG_FILE")"
  if [ "$TEST_MODE" = "1" ]; then
    exec >> "$LOG_FILE" 2>&1
  else
    exec > >(tee -a "$LOG_FILE") 2>&1
  fi
}

self_check() {
  banner "Self-Check"
  validate_environment
  command -v curl >/dev/null 2>&1 || die "curl fehlt."
  local data_dir
  data_dir="$(system_path /var/lib)"
  [ -d "$data_dir" ] || die "$data_dir existiert nicht."
  [ -w "$data_dir" ] || die "$data_dir ist nicht beschreibbar."
  log_ok "Self-Check erfolgreich."
}

remove_repository_files() {
  local path
  for path in \
    /etc/apt/sources.list.d/docker.list \
    /etc/apt/sources.list.d/docker.sources \
    /etc/apt/keyrings/docker.gpg \
    /etc/apt/keyrings/docker.asc; do
    rm -f -- "$(system_path "$path")"
  done
}

install_correct_repo() {
  local keyring_dir source_dir arch key_tmp repo_tmp
  keyring_dir="$(system_path /etc/apt/keyrings)"
  source_dir="$(system_path /etc/apt/sources.list.d)"
  arch="$(dpkg --print-architecture)"
  key_tmp="${key_file}.tmp.$$"
  repo_tmp="${repo_file}.tmp.$$"

  mkdir -p "$keyring_dir" "$source_dir"
  curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" -o "$key_tmp"
  chmod a+r "$key_tmp"

  {
    printf 'Types: deb\n'
    printf 'URIs: https://download.docker.com/linux/%s\n' "$OS_ID"
    printf 'Suites: %s\n' "$OS_CODENAME"
    printf 'Components: stable\n'
    printf 'Architectures: %s\n' "$arch"
    printf 'Signed-By: %s\n' "$key_file"
  } > "$repo_tmp"

  remove_repository_files
  mv -f -- "$key_tmp" "$key_file"
  mv -f -- "$repo_tmp" "$repo_file"
}

installed_packages() {
  local package status
  for package in "$@"; do
    status="$(dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null || true)"
    [[ "$status" == ii* ]] && printf '%s\n' "$package"
  done
  return 0
}

remove_conflicting_packages() {
  local packages=()
  # Package names cannot contain whitespace; word splitting is intentional.
  # shellcheck disable=SC2207
  packages=($(installed_packages \
    docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc))
  if [ "${#packages[@]}" -gt 0 ]; then
    apt-get remove -y "${packages[@]}"
  else
    log_info "Keine konfliktbehafteten Pakete gefunden."
  fi
}

docker_was_running() {
  systemctl is-active --quiet docker.service
}

stop_docker_for_backup() {
  local was_running=1
  docker_was_running || was_running=0
  systemctl stop docker.service docker.socket containerd.service 2>/dev/null || true
  printf '%s' "$was_running"
}

start_docker_after_backup() {
  local was_running="$1"
  if [ "$was_running" -eq 1 ]; then
    systemctl start containerd.service docker.service
  fi
}

perform_backup() {
  local timestamp output was_running source relative
  local sources=()
  timestamp="$(date +%Y%m%d-%H%M%S)"
  [ -n "$BACKUP_DIR" ] || BACKUP_DIR="$(system_path /var/backups)"
  mkdir -p "$BACKUP_DIR"
  output="${BACKUP_DIR}/docker-backup-${timestamp}.tar.gz"

  was_running="$(stop_docker_for_backup)"
  for relative in var/lib/docker var/lib/containerd etc/docker; do
    source="$(system_path "/$relative")"
    [ -e "$source" ] && sources+=("$relative")
  done
  if [ "${#sources[@]}" -eq 0 ]; then
    start_docker_after_backup "$was_running"
    die "Keine Docker-Daten für ein Backup gefunden."
  fi

  log_info "Docker ist für ein konsistenteres Host-Backup angehalten."
  if ! tar -czf "$output" -C "${SYSTEM_ROOT:-/}" "${sources[@]}"; then
    start_docker_after_backup "$was_running"
    die "Backup fehlgeschlagen."
  fi
  start_docker_after_backup "$was_running"
  log_ok "Backup gespeichert: $output"
}

verify_docker_installation() {
  docker --version
  docker compose version
  docker buildx version
  docker info >/dev/null
  if [ "$HELLO" -eq 1 ]; then
    docker run --rm hello-world
  fi
  log_ok "Docker Engine, Compose und Buildx wurden verifiziert."
}

install_docker_packages() {
  local install_args=(-y)
  if [ "$FORCE_UPGRADE" -eq 1 ]; then
    install_args+=(--reinstall)
  fi
  apt-get install "${install_args[@]}" \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

perform_install() {
  banner "Installation"
  validate_environment
  progress_init "Docker-Installation gestartet."

  remove_repository_files
  apt-get update
  apt-get install -y ca-certificates curl
  command -v curl >/dev/null 2>&1 || die "curl konnte nicht installiert werden."
  progress_step "Voraussetzungen installiert."

  remove_conflicting_packages
  progress_step "Konfliktpakete geprüft."

  install_correct_repo
  apt-get update
  progress_step "Offizielles Docker-Repository eingerichtet."

  install_docker_packages
  systemctl enable --now containerd.service docker.service
  progress_step "Docker Engine und Plugins installiert."

  if [ -n "$ADD_USER" ]; then
    id "$ADD_USER" >/dev/null 2>&1 || die "Benutzer '$ADD_USER' existiert nicht."
    usermod -aG docker "$ADD_USER"
    log_warn "Gruppenänderung für '$ADD_USER' wird nach erneutem Login aktiv."
  fi

  verify_docker_installation
  apt-get autoremove -y
  progress_done "Docker wurde erfolgreich installiert."
}

perform_upgrade() {
  banner "Upgrade"
  validate_environment
  progress_init "Docker-Upgrade gestartet."

  if [ "$BACKUP_DATA" -eq 1 ]; then
    perform_backup
  fi
  remove_repository_files
  apt-get update
  apt-get install -y ca-certificates curl
  command -v curl >/dev/null 2>&1 || die "curl konnte nicht installiert werden."
  install_correct_repo
  apt-get update
  install_docker_packages
  systemctl enable --now containerd.service docker.service
  verify_docker_installation
  apt-get autoremove -y
  progress_done "Docker wurde erfolgreich aktualisiert."
}

confirm_data_removal() {
  if [ "$REMOVE_DATA" -eq 1 ]; then
    return 0
  fi
  if [ "$KEEP_DATA" -eq 1 ] || [ "$NON_INTERACTIVE" -eq 1 ]; then
    return 1
  fi
  local answer
  printf 'Docker-Daten endgültig löschen? Tippe DELETE zum Bestätigen: '
  read -r answer
  [ "$answer" = "DELETE" ]
}

perform_uninstall() {
  banner "Deinstallation"
  validate_environment
  progress_init "Docker-Deinstallation gestartet."

  systemctl stop docker.service docker.socket containerd.service 2>/dev/null || true
  if [ "$BACKUP_DATA" -eq 1 ]; then
    perform_backup
  fi

  local packages=()
  # Package names cannot contain whitespace; word splitting is intentional.
  # shellcheck disable=SC2207
  packages=($(installed_packages docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras))
  if [ "${#packages[@]}" -gt 0 ]; then
    apt-get purge -y "${packages[@]}"
    apt-get autoremove -y --purge
  else
    log_info "Keine offiziellen Docker-Pakete gefunden."
  fi

  remove_repository_files
  if confirm_data_removal; then
    rm -rf -- "$(system_path /var/lib/docker)" "$(system_path /var/lib/containerd)"
    log_warn "Docker-Daten wurden gelöscht."
  else
    log_info "Docker-Daten wurden behalten."
  fi

  systemctl daemon-reload
  progress_done "Docker wurde erfolgreich deinstalliert."
}

main() {
  init_colors
  parse_arguments "$@"
  init_colors

  if [ -z "$ACTION" ]; then
    if [ "$NON_INTERACTIVE" -eq 1 ]; then
      die "Keine Aktion gewählt und --non-interactive gesetzt."
    fi
    show_menu_and_pick_action
  fi

  require_root
  configure_logging
  if [ "$CLEAR" -eq 1 ] && is_tty; then
    tput clear 2>/dev/null || true
  fi

  case "$ACTION" in
    install) perform_install ;;
    upgrade) perform_upgrade ;;
    uninstall) perform_uninstall ;;
    selfcheck) self_check ;;
  esac
}

trap 'on_error "$?" "$LINENO"' ERR
trap progress_cleanup EXIT
main "$@"
