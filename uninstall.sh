#!/usr/bin/env bash
# Deinstalliert Rootful Docker + Compose v2. Optional Daten behalten.

set -euo pipefail
CSI='\033['; BLUE="${CSI}1;34m"; YEL="${CSI}1;33m"; RED="${CSI}1;31m"; END="${CSI}0m"
info(){ echo -e "${BLUE}[INFO]${END} $*"; }
warn(){ echo -e "${YEL}[WARN]${END} $*"; }
err(){  echo -e "${RED}[ERR ]${END} $*"; }
die(){  err "$*"; exit 1; }

KEEP_DATA=""
LOGFILE="/var/log/docker-uninstall.log"
NO_CLEAR=""

# ---------- Args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-data) KEEP_DATA="1";;
    --no-clear) NO_CLEAR="1";;
    --log-file=*) LOGFILE="${1#*=}";;
    -h|--help)
      cat <<EOF
Usage: sudo ./uninstall.sh [--keep-data] [--no-clear] [--log-file=/path/file.log]
  --keep-data     Behält /var/lib/docker und /var/lib/containerd (keine Datenlöschung)
  --no-clear      Bildschirm nicht löschen
  --log-file=PATH Pfad fürs Logfile (Default: $LOGFILE)
EOF
      exit 0;;
  esac
  shift
done

# ---------- Preconditions ----------
[[ $EUID -eq 0 ]] || die "Bitte als root ausführen (sudo ./uninstall.sh)."
[[ -r /etc/os-release ]] || die "/etc/os-release nicht gefunden"
. /etc/os-release
OS="${ID:-}"; [[ "$OS" =~ ^(debian|ubuntu)$ ]] || die "Nur Debian/Ubuntu werden unterstützt."

# ---------- Logging / Clean screen ----------
mkdir -p "$(dirname "$LOGFILE")"
exec > >(stdbuf -oL tee -a "$LOGFILE") 2>&1
[[ -z "$NO_CLEAR" ]] && echo -ne "\033c"
info "Logfile: $LOGFILE"

# ---------- Services stoppen ----------
info "Stoppe & deaktiviere Docker-Dienste…"
systemctl disable --now docker.service docker.socket || true
systemctl disable --now containerd.service || systemctl disable --now containerd || true

# ---------- Laufende Container/Objekte entfernen ----------
info "Entferne Container/Images/Volumes/Netzwerke…"
docker ps -aq | xargs -r docker rm -f || true
docker images -aq | xargs -r docker rmi -f || true
docker volume ls -q | xargs -r docker volume rm || true
docker network ls -q --filter type=custom | xargs -r docker network rm || true

# ---------- Pakete entfernen ----------
info "Purge Docker-Pakete…"
apt-get purge -y docker-ce docker-ce-cli containerd.io containerd docker-buildx-plugin docker-compose-plugin docker-compose-v2 || true
apt-get autoremove -y || true

# ---------- Repo & Keys entfernen ----------
info "Entferne Docker-Repo & Keys…"
rm -f /etc/apt/sources.list.d/docker.list \
      /etc/apt/keyrings/docker.asc \
      /etc/apt/keyrings/docker.gpg || true
apt-get update || true

# ---------- Daten optional entfernen ----------
if [[ -z "$KEEP_DATA" ]]; then
  info "Lösche Daten- & Config-Verzeichnisse…"
  rm -rf /var/lib/docker /var/lib/containerd /etc/docker /var/run/docker.sock || true
else
  warn "Daten behalten: /var/lib/docker und /var/lib/containerd bleiben bestehen."
fi

# ---------- docker-Gruppe optional entfernen ----------
if getent group docker >/dev/null 2>&1; then
  if ! getent group docker | awk -F: '{print $4}' | grep -q . ; then
    info "Entferne leere Gruppe 'docker'…"
    groupdel docker 2>/dev/null || true
  else
    warn "Gruppe 'docker' hat noch Mitglieder – nicht entfernt."
  fi
fi

info "Deinstallation abgeschlossen."
