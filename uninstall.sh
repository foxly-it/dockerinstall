#!/usr/bin/env bash
# Docker & Compose Uninstaller – Foxly edition (with Whale + Progressbar)
set -Eeuo pipefail

# ----- Flags -----
KEEP_DATA=0
CLEAR=1
LOG_FILE="/var/log/docker-uninstall.log"

for arg in "$@"; do
  case "$arg" in
    --keep-data) KEEP_DATA=1;;
    --no-clear)  CLEAR=0;;
    --log-file=*) LOG_FILE="${arg#*=}";;
    --no-color)  :;;
    *) ;;
  esac
done

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

# ----- Visuals -----
# shellcheck disable=SC1091
. "$(dirname "$0")/visuals.sh" 2>/dev/null || . "./visuals.sh"
parse_no_color_flag "$@"
[ "$CLEAR" -eq 1 ] && tput clear 2>/dev/null || true
whale_banner "uninstall" "$@"

# ----- Root/Distro -----
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Bitte mit sudo/root ausführen."; exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Dieses Script unterstützt aktuell apt-basierte Systeme (Debian/Ubuntu)."; exit 1
fi

PHASES=(
  "Dienste stoppen"
  "Pakete entfernen"
  "Repo & Key entfernen"
  "Datenverzeichnisse (optional)"
  "Gruppen/Users Hinweis"
  "Cleanup"
)
progress_init "${#PHASES[@]}" "Uninstall dockerinstall – Entferne Komponenten"

# 1) Stop services
systemctl stop docker 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true
progress_step "${PHASES[0]}"

# 2) Remove packages
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose 2>/dev/null || true
apt-get autoremove -y --purge 2>/dev/null || true
progress_step "${PHASES[1]}"

# 3) Remove repo/key
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.gpg
apt-get update -y
progress_step "${PHASES[2]}"

# 4) Data (optional)
if [ "$KEEP_DATA" -eq 0 ]; then
  rm -rf /var/lib/docker /var/lib/containerd
else
  echo "Daten behalten: /var/lib/docker und /var/lib/containerd wurden nicht gelöscht."
fi
progress_step "${PHASES[3]}}"

# 5) Group note
if getent group docker >/dev/null 2>&1; then
  echo "Hinweis: Gruppe 'docker' existiert ggf. weiterhin. Bei Bedarf manuell entfernen, wenn leer: groupdel docker"
fi
progress_step "${PHASES[4]}"

# 6) Cleanup
rm -f /etc/systemd/system/docker.service.d/* 2>/dev/null || true
systemctl daemon-reload || true
progress_step "${PHASES[5]}"

progress_done "Deinstallation abgeschlossen"
echo "🧹 Docker entfernt. Log: $LOG_FILE"
