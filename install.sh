#!/usr/bin/env bash
# Docker & Compose Installer – Foxly edition (Banner + Progress)
set -Eeuo pipefail

# ----- Defaults / Flags -----
ADD_USER=""
HELLO=1
CLEAR=1
LOG_FILE="/var/log/docker-install.log"

# ----- Args -----
for arg in "$@"; do
  case "$arg" in
    --add-user=*) ADD_USER="${arg#*=}";;
    --add-user)   shift; ADD_USER="${1:-}";;
    --no-hello)   HELLO=0;;
    --no-clear)   CLEAR=0;;
    --log-file=*) LOG_FILE="${arg#*=}";;
    --no-color)   : ;; # handled in visuals
    *) ;; 
  esac
done

# ----- Prep logging -----
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

# ----- Visuals -----
# shellcheck disable=SC1091
. "$(dirname "$0")/visuals.sh" 2>/dev/null || . "./visuals.sh"
parse_no_color_flag "$@"
[ "$CLEAR" -eq 1 ] && tput clear 2>/dev/null || true
whale_banner "install" "$@"

# ----- Root check -----
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Bitte mit sudo/root ausführen."
  exit 1
fi

# ----- Distro check -----
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Dieses Script unterstützt aktuell apt-basierte Systeme (Debian/Ubuntu)."
  exit 1
fi

# ----- Steps -----
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

# 1) Prereqs
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
progress_step "${PHASES[0]}"

# 2) Conflicts
apt-get remove -y docker docker.io docker-engine docker-doc podman-docker docker-compose docker-compose-plugin 2>/dev/null || true
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
progress_step "${PHASES[1]}"

# 3) Repo + Key
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi
. /etc/os-release
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
progress_step "${PHASES[2]}"

# 4) Install Engine + Compose
progress_set 35 "Pakete werden installiert …"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
progress_set 55 "Pakete installiert – finalisiere …"
progress_step "${PHASES[3]}"

# 5) Services
systemctl enable --now docker
systemctl enable --now containerd
progress_step "${PHASES[4]}"

# 6) User/Gruppen (optional)
if [ -n "$ADD_USER" ]; then
  if id "$ADD_USER" >/dev/null 2>&1; then
    usermod -aG docker "$ADD_USER"
    echo "User '$ADD_USER' wurde zur Gruppe 'docker' hinzugefügt (Neuanmeldung nötig)."
  else
    echo "Hinweis: Benutzer '$ADD_USER' existiert nicht – Schritt übersprungen."
  fi
fi
progress_step "${PHASES[5]}"

# 7) Hello-World (optional)
if [ "$HELLO" -eq 1 ]; then
  progress_set 85 "Hello-World wird ausgeführt …"
  if command -v docker >/dev/null 2>&1; then
    docker run --rm hello-world || true
  fi
fi
progress_step "${PHASES[6]}"

# 8) Cleanup
apt-get autoremove -y >/dev/null 2>&1 || true
progress_step "${PHASES[7]}"

progress_done "Installation abgeschlossen"
echo "✅ Docker installiert. Log: $LOG_FILE"
