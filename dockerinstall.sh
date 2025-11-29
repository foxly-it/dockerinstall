#!/usr/bin/env bash
# ============================================================
#  dockerinstall.sh – Foxly Edition
#  Single-File Docker Manager
#  Install | Upgrade | Uninstall | Self-Check | Backup
#  Fully integrated visuals.sh + compose_pull_compact
#  Compatible: Debian 12 & 13, Ubuntu 22.04+
#  by Mark “Foxly IT” Schenk – foxly.de
#  Version: 2.0
# ============================================================

set -Eeuo pipefail

# ============================================================
#  VISUALS.SH – vollständig integriert
# ============================================================

SCRIPT_ANIM="${SCRIPT_ANIM:-1}"
NO_COLOR="${NO_COLOR:-0}"
FORCE_NO_COLOR="${FORCE_NO_COLOR:-0}"

# ---------- TTY / Colors ----------
_is_tty() { [ -t 1 ]; }
_term_cols() { tput cols 2>/dev/null || echo 80; }

if [ "$NO_COLOR" = "1" ] || [ "$FORCE_NO_COLOR" = "1" ] || ! _is_tty; then
  C_RESET=""; C_DIM=""; C_BOLD=""
  C_TEXT=""; C_WATER=""; C_FOX=""; C_ACCENT=""
else
  C_RESET="$(printf '\033[0m')"
  C_DIM="$(printf '\033[2m')"
  C_BOLD="$(printf '\033[1m')"
  C_TEXT="$(printf '\033[38;5;250m')"
  C_WATER="$(printf '\033[38;5;45m')"
  C_FOX="$(printf '\033[38;5;214m')"
  C_ACCENT="$(printf '\033[38;5;223m')"
fi

# ---------- Center helpers ----------
_center_print() {
  local cols pad line plain width left
  cols="$(_term_cols)"
  while IFS= read -r line; do
    plain="${line//\033\[[0-9;]*m/}"
    width=${#plain}
    if [ "$width" -lt "$cols" ]; then
      pad=$(( (cols - width) / 2 ))
      left="$(printf '%*s' "$pad" '')"
    else
      left=""
    fi
    printf "%s%s\n" "$left" "$line"
  done
}

_center_block() {
  local lines=() line plain width max=0
  while IFS= read -r line; do
    lines+=("$line")
    plain="${line//\033\[[0-9;]*m/}"
    width=${#plain}
    (( width > max )) && max=$width
  done
  local cols pad left; cols="$(_term_cols)"
  if (( max < cols )); then
    pad=$(( (cols - max) / 2 ))
    left="$(printf '%*s' "$pad" '')"
  else
    left=""
  fi
  for line in "${lines[@]}"; do
    printf "%s%s\n" "$left" "$line"
  done
}

# ---------- Tiny bubbles ----------
_bubbles_frame() {
  case "$1" in
    0) printf "   ·    \n";;
    1) printf "    ·   \n";;
    2) printf "     ·  \n";;
    3) printf "      · \n";;
  esac
}

parse_no_color_flag() { 
  for a in "$@"; do 
    [ "$a" = "--no-color" ] && FORCE_NO_COLOR=1 
  done 
}

# ---------- Foxly ASCII ----------
_fox_art() {
  local mode="${1:-install}"
  local E="^_^" M="^"
  if [ "$mode" = "uninstall" ]; then
    E="x_x"; M="_"
  elif [ "$mode" = "upgrade" ]; then
    E="o_o"; M="^"
  fi

  cat <<EOF
                         ${C_WATER}~   ~    ~~~    ~   ~${C_RESET}
                   ${C_WATER}~~~~${C_RESET}                        ${C_WATER}~~~~${C_RESET}
                         ${C_FOX}/\\     /\\${C_RESET}
                        ${C_FOX}{  \`---'  }${C_RESET}
                        ${C_FOX}{  ${C_ACCENT}${E}${C_FOX}   }${C_RESET}
                        ${C_FOX}~~>  ${C_ACCENT}${M}${C_FOX}  <~~${C_RESET}
                         ${C_FOX}\\  \\|/  /${C_RESET}
                          ${C_FOX}\`-----'${C_RESET}
                        ${C_WATER}[ ][ ][ ]${C_RESET}
                        ${C_WATER}[ ][ ][ ]${C_RESET}
                         ${C_WATER}\`-----'${C_RESET}
EOF
}

# ---------- Banner ----------
whale_banner() {
  local mode="${1:-install}"
  shift || true

  for arg in "$@"; do [ "$arg" = "--no-color" ] && FORCE_NO_COLOR=1; done

  local title
  case "$mode" in
    install)   title="${C_BOLD}${C_TEXT}Install dockerinstall – Foxly is on duty!${C_RESET}";;
    upgrade)   title="${C_BOLD}${C_TEXT}Upgrade dockerinstall – Polishing the fleet…${C_RESET}";;
    uninstall) title="${C_BOLD}${C_TEXT}Uninstall dockerinstall – The Fox takes a bow.${C_RESET}";;
    *)         title="${C_BOLD}${C_TEXT}dockerinstall – Foxly Tool${C_RESET}";;
  esac

  printf "%s\n" "$title" | _center_print

  if [ "$SCRIPT_ANIM" = "1" ] && _is_tty; then
    for f in 0 1 2 3; do
      _bubbles_frame "$f" | _center_print
      sleep 0.05
    done
  fi

  _fox_art "$mode" | _center_block
  printf "%s\n" "${C_DIM}(Foxly ready – systems online.)${C_RESET}" | _center_print
}

# ============================================================
#  Mini-Progressbar
# ============================================================

PROG_TOTAL=0
PROG_CUR=0
PROG_ACTIVE=0

progress__hide_cursor() { _is_tty && tput civis 2>/dev/null || true; }
progress__show_cursor() { _is_tty && tput cnorm 2>/dev/null || true; }

progress__draw() {
  local p="${1:-0}" label="${2:-}" cols barw filled empty
  cols="$(_term_cols)"
  barw=40
  [ "$cols" -lt 70 ] && barw=28
  [ "$cols" -lt 50 ] && barw=20

  local filled_len=$(( (p * barw) / 100 ))
  (( filled_len > barw )) && filled_len="$barw"
  local empty_len=$(( barw - filled_len ))

  filled="$(printf '%*s' "$filled_len" '' | tr ' ' '#')"
  empty="$(printf '%*s' "$empty_len" '' | tr ' ' '-')"

  printf "\r%s ${C_WATER}[${C_RESET}%s%s${C_WATER}]${C_RESET} ${C_TEXT}%3d%%${C_RESET}  ${C_DIM}%s${C_RESET}" \
    "${C_BOLD}${C_TEXT}▶${C_RESET}" "$filled" "$empty" "$p" "$label"
}

progress_init() {
  PROG_TOTAL="${1:-0}"
  PROG_CUR=0
  PROG_ACTIVE=1
  if _is_tty; then
    progress__hide_cursor
    printf "%s\n" "${C_BOLD}${C_TEXT}${2:-Progress}${C_RESET}"
    progress__draw 0 "Startet …"
  else
    echo "[INFO] ${2:-Progress}"
  fi
  trap 'progress_cleanup' EXIT
}

progress_step() {
  local label="${1:-}"
  PROG_CUR=$(( PROG_CUR + 1 ))
  local pct=$(( (PROG_CUR * 100) / PROG_TOTAL ))
  (( pct > 100 )) && pct=100

  if _is_tty; then
    progress__draw "$pct" "$label"
  else
    echo "[${PROG_CUR}/${PROG_TOTAL}] $label"
  fi
}

progress_set() {
  local pct="${1:-0}" label="${2:-}"
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100

  if _is_tty; then
    progress__draw "$pct" "$label"
  else
    echo "[$pct%%] $label"
  fi
}

progress_done() {
  local label="${1:-Fertig}"
  if _is_tty; then
    progress__draw 100 "$label"
    printf "\n"
  else
    echo "[DONE] $label"
  fi
  progress__show_cursor
  PROG_ACTIVE=0
  trap - EXIT
}

progress_cleanup() {
  if [ "$PROG_ACTIVE" -eq 1 ]; then
    _is_tty && printf "\n"
    progress__show_cursor
    PROG_ACTIVE=0
  fi
}

# ============================================================
#  compose_pull_compact  (3-line calm output)
# ============================================================

_COMPACT_NAMES=()
_COMPACT_TOTALS=()
_COMPACT_CURS=()
_COMPACT_DONE=()
_COMPACT_IDXMAP=""
_COMPACT_LINES=3

_compact__index_of() {
  local nm="$1" pair
  for pair in $_COMPACT_IDXMAP; do
    case "$pair" in "$nm":*) echo "${pair##*:}"; return 0;;
    esac
  done
  echo "-1"
}

_compact__fmt_bytes() {
  local b="${1:-0}"
  if [ "$b" -lt 1024 ]; then printf "%dB" "$b"; return; fi
  local kb=$(( b / 1024 ))
  if [ "$kb" -lt 1024 ]; then printf "%dKB" "$kb"; return; fi
  local mb=$(( kb / 1024 ))
  if [ "$mb" -lt 1024 ]; then printf "%dMB" "$mb"; return; fi
  local gb=$(( mb / 1024 ))
  printf "%dGB" "$gb"
}

_compact__bar() {
  local p=$1 w=$2
  (( p < 0 )) && p=0
  (( p > 100 )) && p=100
  (( w < 10 )) && w=10
  local f=$(( (p * w) / 100 ))
  (( f > w )) && f=$w
  local e=$(( w - f ))
  printf "[%s%s]" \
    "$(printf '%*s' "$f" '' | tr ' ' '=')" \
    "$(printf '%*s' "$e" '' | tr ' ' ' ')"
}

_compact__line() {
  local i="$1"
  local nm="${_COMPACT_NAMES[$i]}"
  local tot="${_COMPACT_TOTALS[$i]}"
  local cur="${_COMPACT_CURS[$i]}"
  local dn="${_COMPACT_DONE[$i]}"

  local mark bar pct right cols text
  cols="$(_term_cols)"

  if [ "$dn" -eq 1 ]; then
    mark="✓"
    bar="$(_compact__bar 100 22)"
    right="done"
  else
    mark="⣿"
    if [ "$tot" -gt 0 ]; then
      pct=$(( (100 * cur) / tot ))
      (( pct > 100 )) && pct=100
      bar="$(_compact__bar "$pct" 22)"
      right="$(printf "%s/%s  (%3d%%)" "$(_compact__fmt_bytes "$cur")" "$(_compact__fmt_bytes "$tot")" "$pct")"
    else
      bar="$(_compact__bar 0 22)"
      right="waiting"
    fi
  fi

  text=$(printf " %s  %-18s  ${C_WATER}%s${C_RESET}  %s" "$mark" "$nm" "$bar" "$right")
  printf "%-*s\n" "$cols" "$text"
}

compose_pull_compact_init() {
  _COMPACT_NAMES=(); _COMPACT_TOTALS=(); _COMPACT_CURS=(); _COMPACT_DONE=()
  _COMPACT_IDXMAP=""
  for i in 1 2 3; do
    nm="${1:-item$i}"
    tot="${2:-0}"
    shift 2 || true
    _COMPACT_NAMES+=("$nm")
    _COMPACT_TOTALS+=("$tot")
    _COMPACT_CURS+=(0)
    _COMPACT_DONE+=(0)
  done
  for i in 0 1 2; do
    _COMPACT_IDXMAP="$_COMPACT_IDXMAP ${_COMPACT_NAMES[$i]}:$i"
  done
  _compact__line 0
  _compact__line 1
  _compact__line 2
}

compose_pull_compact_set() {
  local nm="$1" cur="${2:-0}" idx
  idx="$(_compact__index_of "$nm")"
  [ "$idx" -lt 0 ] && return 0
  _COMPACT_CURS[$idx]="$cur"
  tput cuu "$_COMPACT_LINES" 2>/dev/null || printf "\033[%dA" "$_COMPACT_LINES"
  _compact__line 0
  _compact__line 1
  _compact__line 2
}

compose_pull_compact_done() {
  local nm="$1" idx
  idx="$(_compact__index_of "$nm")"
  [ "$idx" -lt 0 ] && return 0
  _COMPACT_DONE[$idx]=1
  _COMPACT_CURS[$idx]="${_COMPACT_TOTALS[$idx]}"
  tput cuu "$_COMPACT_LINES" 2>/dev/null || printf "\033[%dA" "$_COMPACT_LINES"
  _compact__line 0
  _compact__line 1
  _compact__line 2
}

compose_pull_compact_finish() { printf "\n"; }
# ============================================================
#  BLOCK 2 – CORE FUNCTIONS (Backup, Repo, Self-Check, Status)
# ============================================================

# ------------------------------------------------------------
#  GLOBAL FLAGS (für Block 3 initialisiert)
# ------------------------------------------------------------
ACTION=""
ADD_USER=""
HELLO=1
CLEAR=1
LOG_FILE="/var/log/docker-install.log"
NON_INTERACTIVE=0
FORCE_UPGRADE=0
BACKUP_DATA=0


# ------------------------------------------------------------
#  PRINT HELPERS
# ------------------------------------------------------------
log_info()  { printf "${C_WATER}[INFO]${C_RESET}  %s\n" "$1"; }
log_warn()  { printf "${C_ACCENT}[WARN]${C_RESET}  %s\n" "$1"; }
log_err()   { printf "${C_FOX}[FAIL]${C_RESET}  %s\n" "$1"; }
log_ok()    { printf "${C_TEXT}[ OK ]${C_RESET}  %s\n" "$1"; }


# ------------------------------------------------------------
#  SELF-CHECK – prüft alles bevor Install/Upgrade läuft
# ------------------------------------------------------------
self_check() {
  whale_banner "install"

  printf "\n${C_BOLD}${C_TEXT}Self-Check gestartet …${C_RESET}\n\n"

  local errors=0

  # Root?
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    log_err "Script muss mit root/sudo ausgeführt werden."
    errors=$((errors+1))
  else
    log_ok "Root-Rechte vorhanden"
  fi

  # apt vorhanden?
  if ! command -v apt-get >/dev/null 2>&1; then
    log_err "Dies ist kein Debian-/Ubuntu-System (apt-get fehlt)."
    errors=$((errors+1))
  else
    log_ok "APT-System erkannt"
  fi

  # curl
  if ! command -v curl >/dev/null 2>&1; then
    log_err "curl fehlt"
    errors=$((errors+1))
  else
    log_ok "curl installiert"
  fi

  # gpg
  if ! command -v gpg >/dev/null 2>&1; then
    log_err "gpg fehlt"
    errors=$((errors+1))
  else
    log_ok "gpg installiert"
  fi

  # systemd?
  if ! pidof systemd >/dev/null 2>&1; then
    log_err "Systemd wird nicht ausgeführt – Docker benötigt systemd."
    errors=$((errors+1))
  else
    log_ok "systemd läuft"
  fi

  # docker vorhanden?
  if command -v docker >/dev/null 2>&1; then
    log_ok "Docker CLI vorhanden"
  else
    log_warn "Docker CLI fehlt (nicht schlimm für Installation)"
  fi

  # /var/lib/docker beschreibbar?
  if [ -d /var/lib ] && [ ! -w /var/lib ]; then
    log_err "/var/lib ist nicht beschreibbar."
    errors=$((errors+1))
  else
    log_ok "/var/lib beschreibbar"
  fi

  # apt-Lock prüfen
  if fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
     fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
     fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
    log_err "APT-Lock aktiv – anderer Prozess installiert/updated gerade!"
    errors=$((errors+1))
  else
    log_ok "APT-Lock frei"
  fi

  # Ergebnis
  if [ "$errors" -gt 0 ]; then
    printf "\n${C_FOX}Self-Check hat %d Fehler gefunden – Abbruch.${C_RESET}\n" "$errors"
    exit 1
  fi

  printf "\n${C_WATER}Self-Check erfolgreich!${C_RESET}\n"
  exit 0
}


# ------------------------------------------------------------
#  BACKUP (/var/lib/docker → tar.gz)
# ------------------------------------------------------------
perform_backup() {
  local TS
  TS="$(date +%Y%m%d-%H%M%S)"
  local OUT="/var/backups/docker-backup-${TS}.tar.gz"

  mkdir -p /var/backups

  whale_banner "upgrade"

  log_info "Backup erstellt → $OUT"
  progress_init 3 "Backup läuft …"

  progress_step "Vorbereitung"

  tar -czf "$OUT" /var/lib/docker /var/lib/containerd 2>/dev/null || {
    progress_done "Fehler"
    log_err "Backup fehlgeschlagen"
    exit 1
  }

  progress_step "Daten komprimiert"
  progress_step "Abschluss"

  progress_done "Backup abgeschlossen"
  log_ok "Backup gespeichert in: $OUT"
}


# ------------------------------------------------------------
#  DOCKER STATUS – läuft der Dienst?
# ------------------------------------------------------------
docker_is_running() {
  if systemctl is-active --quiet docker 2>/dev/null; then
    return 0
  fi
  if systemctl is-active --quiet containerd 2>/dev/null; then
    return 0
  fi
  return 1
}

docker_status_report() {
  if docker_is_running; then
    log_ok "Docker läuft"
  else
    log_warn "Docker läuft NICHT"
  fi
}


# ------------------------------------------------------------
#  DEBIAN/UBUNTU Versionsdaten
# ------------------------------------------------------------
detect_os() {
  . /etc/os-release
  OS_ID="$ID"
  OS_CODENAME="$VERSION_CODENAME"
  OS_VERSION="$VERSION_ID"
}

# ------------------------------------------------------------
#  Versions-Helper (installierte vs. Repo-Version)
# ------------------------------------------------------------
docker_current_version() {
  docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//'
}

docker_repo_version() {
  apt-cache policy docker-ce 2>/dev/null | awk '/Candidate:/ {print $2}'
}

docker_needs_upgrade() {
  local cur latest
  cur="$(docker_current_version)"
  latest="$(docker_repo_version)"
  if [ -z "$cur" ]; then
    return 0
  fi
  if [ -z "$latest" ] || [ "$latest" = "(none)" ]; then
    return 0
  fi
  dpkg --compare-versions "$latest" gt "$cur"
}


repo_file="/etc/apt/sources.list.d/docker.list"
key_file="/etc/apt/keyrings/docker.gpg"


# ------------------------------------------------------------
#  ERKENNE Falsche/alte Docker-Repos
# ------------------------------------------------------------
repo_is_correct() {
  if [[ ! -f "$repo_file" ]]; then
    return 1
  fi
  if grep -q "$OS_CODENAME" "$repo_file"; then
    return 0
  fi
  return 1
}


# ------------------------------------------------------------
#  Entferne alle alten Docker-Repos
# ------------------------------------------------------------
remove_old_repos() {
  rm -f /etc/apt/sources.list.d/docker*.list
  rm -f /etc/apt/keyrings/docker.gpg
}


# ------------------------------------------------------------
#  INSTALLIEREN des korrekten Docker-Repos
# ------------------------------------------------------------
install_correct_repo() {
  detect_os

  mkdir -p /etc/apt/keyrings

  curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" \
    | gpg --dearmor -o "$key_file"

  chmod a+r "$key_file"

  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=$key_file] \
https://download.docker.com/linux/${OS_ID} ${OS_CODENAME} stable" \
    > "$repo_file"
}


# ------------------------------------------------------------
#  Sicherer Prompt (übersprungen bei NON_INTERACTIVE=1)
# ------------------------------------------------------------
safe_prompt() {
  local question="$1"
  local default="$2"

  if [ "$NON_INTERACTIVE" -eq 1 ]; then
    echo "$default"
    return
  fi

  echo -n "$question "
  read -r answer
  echo "${answer:-$default}"
}


# ------------------------------------------------------------
#  WÄHLE AKTION über Menü (falls nicht non-interactive)
# ------------------------------------------------------------
show_menu_and_pick_action() {
  whale_banner "install"
  echo ""
  echo "   Was möchtest du tun?"
  echo ""
  echo "   1) Docker installieren"
  echo "   2) Docker Upgrade (Repo fix + Reinstall)"
  echo "   9) Docker deinstallieren"
  echo ""
  printf "   Auswahl: "

  read -r choice

  case "$choice" in
    1) ACTION="install";;
    2) ACTION="upgrade";;
    9) ACTION="uninstall";;
    *) echo "Ungültige Eingabe."; exit 1;;
  esac
}


# ------------------------------------------------------------
#  SETUP LOGGING
# ------------------------------------------------------------
setup_logging() {
  mkdir -p "$(dirname "$LOG_FILE")"
  exec > >(tee -a "$LOG_FILE") 2>&1
}


# ------------------------------------------------------------
#  PARSE ARGUMENTS (für Block 3 relevant)
# ------------------------------------------------------------
parse_arguments() {
  for arg in "$@"; do
    case "$arg" in
      install)      ACTION="install";;
      upgrade)      ACTION="upgrade";;
      uninstall)    ACTION="uninstall";;

      --add-user=*) ADD_USER="${arg#*=}";;
      --add-user)   shift; ADD_USER="${1:-}";;

      --no-hello)   HELLO=0;;
      --no-clear)   CLEAR=0;;

      --backup-data) BACKUP_DATA=1;;
      --non-interactive) NON_INTERACTIVE=1;;
      --force-upgrade) FORCE_UPGRADE=1;;

      --self-check) ACTION="selfcheck";;
      --log-file=*) LOG_FILE="${arg#*=}";;

      --no-color)   : ;; # handled by visuals
      *) ;;
    esac
  done
}
# ============================================================
#  BLOCK 3 – INSTALL / UPGRADE / UNINSTALL / MAIN DISPATCH
# ============================================================

# ------------------------------------------------------------
#  INSTALL DOCKER
# ------------------------------------------------------------
perform_install() {
  whale_banner "install"

  PHASES=(
    "System-Check & Prereqs"
    "Konfliktpakete entfernen"
    "Docker-Repo einbinden"
    "Docker Engine & Tools installieren"
    "Services aktivieren"
    "User/Gruppen (optional)"
    "Hello-World Test (optional)"
    "Cleanup"
  )

  progress_init "${#PHASES[@]}" "Install dockerinstall – Setup läuft"

  # PHASE 1
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release
  install -m 0755 -d /etc/apt/keyrings
  progress_step "${PHASES[0]}"

  # PHASE 2
  apt-get remove -y docker docker.io docker-engine docker-doc podman-docker \
      docker-compose docker-compose-plugin 2>/dev/null || true

  apt-get purge -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin 2>/dev/null || true

  progress_step "${PHASES[1]}"

  # PHASE 3 – Repo schreiben
  remove_old_repos
  install_correct_repo
  apt-get update -y
  progress_step "${PHASES[2]}"

  # PHASE 4 – Pakete
  apt-get install -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
  progress_step "${PHASES[3]}"

  # PHASE 5 – Dienste aktivieren
  systemctl enable --now docker
  systemctl enable --now containerd
  progress_step "${PHASES[4]}"

  # PHASE 6 – Optionale Gruppe
  if [ -n "$ADD_USER" ]; then
    if id "$ADD_USER" >/dev/null 2>&1; then
      usermod -aG docker "$ADD_USER"
      log_ok "User '$ADD_USER' zur docker-Gruppe hinzugefügt"
    else
      log_warn "User '$ADD_USER' existiert nicht – übersprungen"
    fi
  fi
  progress_step "${PHASES[5]}"

  # PHASE 7 – Hello World
  if [ "$HELLO" -eq 1 ]; then
    docker run --rm hello-world || true
  fi
  progress_step "${PHASES[6]}"

  # PHASE 8 – Cleanup
  apt-get autoremove -y >/dev/null 2>&1 || true
  progress_step "${PHASES[7]}"

  progress_done "Installation abgeschlossen"
  log_ok "Docker erfolgreich installiert"
}


# ------------------------------------------------------------
#  UPGRADE DOCKER
# ------------------------------------------------------------
perform_upgrade() {
  whale_banner "upgrade"

  if docker_is_running; then
    log_info "Docker läuft – Upgrade kann im Livebetrieb erfolgen."
  else
    log_warn "Docker läuft nicht – trotzdem Upgrade möglich."
  fi

  if [ "$BACKUP_DATA" -eq 1 ]; then
    perform_backup
  fi

  PHASES=(
    "Entferne alte Repos & Keys"
    "Neues Docker-Repo schreiben"
    "APT aktualisieren"
    "Docker neu installieren"
    "Services laden"
    "Cleanup"
  )

  progress_init "${#PHASES[@]}" "Upgrade dockerinstall – Update läuft"

  # PHASE 1
  remove_old_repos
  progress_step "${PHASES[0]}"

  # PHASE 2
  install_correct_repo
  progress_step "${PHASES[1]}"

  # PHASE 3
  apt-get update -y
  progress_step "${PHASES[2]}"

  # PHASE 4
  apt-get install --reinstall -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
  progress_step "${PHASES[3]}"

  # PHASE 5
  systemctl enable --now docker
  systemctl enable --now containerd
  progress_step "${PHASES[4]}"

  # PHASE 6
  apt-get autoremove -y >/dev/null 2>&1 || true
  progress_step "${PHASES[5]}"

  progress_done "Upgrade abgeschlossen"
  log_ok "Docker erfolgreich aktualisiert"
}


# ------------------------------------------------------------
#  UNINSTALL DOCKER
# ------------------------------------------------------------
perform_uninstall() {
  whale_banner "uninstall"

  PHASES=(
    "Dienste stoppen"
    "Pakete entfernen"
    "Repo & Key entfernen"
    "Datenverzeichnisse (optional)"
    "Gruppen-Hinweis"
    "Cleanup"
  )

  progress_init "${#PHASES[@]}" "Uninstall dockerinstall – Entferne Komponenten"

  # PHASE 1
  systemctl stop docker 2>/dev/null || true
  systemctl stop containerd 2>/dev/null || true
  progress_step "${PHASES[0]}"

  # PHASE 2
  apt-get purge -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin docker-compose 2>/dev/null || true

  apt-get autoremove -y --purge 2>/dev/null || true
  progress_step "${PHASES[1]}"

  # PHASE 3
  remove_old_repos
  apt-get update -y
  progress_step "${PHASES[2]}"

  # PHASE 4 – Daten
  if [ "$BACKUP_DATA" -eq 1 ]; then
    perform_backup
  fi

  # Daten ggf. löschen
  if [ "$NON_INTERACTIVE" -eq 1 ]; then
    KEEP=$( [ "$BACKUP_DATA" -eq 1 ] && echo "n" || echo "y" )
  else
    KEEP=$(safe_prompt "Docker-Daten behalten? (y/n)" "y")
  fi

  if [ "$KEEP" = "n" ]; then
    rm -rf /var/lib/docker /var/lib/containerd
    log_warn "Docker-Daten gelöscht"
  else
    log_info "Docker-Daten behalten"
  fi

  progress_step "${PHASES[3]}"

  # PHASE 5 – Hinweis
  if getent group docker >/dev/null 2>&1; then
    log_info "Gruppe 'docker' existiert evtl. noch. Entfernen falls leer: groupdel docker"
  fi
  progress_step "${PHASES[4]}"

  # PHASE 6 – Cleanup
  rm -f /etc/systemd/system/docker.service.d/* 2>/dev/null || true
  systemctl daemon-reload || true
  progress_step "${PHASES[5]}"

  progress_done "Deinstallation abgeschlossen"
  log_ok "Docker erfolgreich entfernt"
}


# ------------------------------------------------------------
#  MAIN
# ------------------------------------------------------------
main() {
  parse_arguments "$@"
  setup_logging

  # Screen clear
  [ "$CLEAR" -eq 1 ] && tput clear 2>/dev/null || true

  detect_os

  # Self-check
  if [ "$ACTION" = "selfcheck" ]; then
    self_check
  fi

  # No action → Menü oder non-interactive Fehler
  if [ -z "$ACTION" ]; then
    if [ "$NON_INTERACTIVE" -eq 1 ]; then
      log_err "Kein Modus gewählt und --non-interactive gesetzt."
      exit 1
    fi
    show_menu_and_pick_action
  fi

  

  # Execute
  case "$ACTION" in
    install)   perform_install ;;
    upgrade)   perform_upgrade ;;
    uninstall) perform_uninstall ;;
    *) log_err "Unbekannte Aktion: $ACTION"; exit 1 ;;
  esac

  docker_status_report
}

main "$@"