#!/usr/bin/env bash
# Rootful Docker + Compose v2 (Debian 12/13, Ubuntu 24.04)

set -euo pipefail

# ---------- UI / Helpers ----------
CSI='\033['; BLUE="${CSI}1;34m"; YEL="${CSI}1;33m"; RED="${CSI}1;31m"; GRE="${CSI}1;32m"; END="${CSI}0m"
info(){ echo -e "${BLUE}[INFO]${END} $*"; }
warn(){ echo -e "${YEL}[WARN]${END} $*"; }
err(){  echo -e "${RED}[ERR ]${END} $*"; }
die(){  err "$*"; exit 1; }

LOGFILE="/var/log/docker-install.log"
ADD_USER=""   # optional: Benutzer der docker-Gruppe hinzufügen
NO_HELLO=""
NO_CLEAR=""

# ---------- Args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --add-user) shift; ADD_USER="${1:-}";;
    --no-hello) NO_HELLO="1";;
    --no-clear) NO_CLEAR="1";;
    --log-file=*) LOGFILE="${1#*=}";;
    -h|--help)
      cat <<EOF
Usage: sudo ./install.sh [--add-user <username>] [--no-hello] [--no-clear] [--log-file=/path/file.log]
  --add-user USER   Fügt USER der 'docker'-Gruppe hinzu (root-ähnliche Rechte!)
  --no-hello        Überspringt 'docker run hello-world' Kurztest
  --no-clear        Bildschirm nicht löschen
  --log-file=PATH   Pfad fürs Logfile (Default: $LOGFILE)
EOF
      exit 0
      ;;
  esac
  shift
done

# ---------- Preconditions ----------
[[ $EUID -eq 0 ]] || die "Bitte als root ausführen (sudo ./install.sh)."
[[ -r /etc/os-release ]] || die "/etc/os-release nicht gefunden."
. /etc/os-release
OS="${ID:-}"
CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
[[ -n "$CODENAME" ]] || die "Konnte Debian/Ubuntu-Codename nicht ermitteln."
[[ "$OS" =~ ^(debian|ubuntu)$ ]] || die "Nur Debian/Ubuntu werden unterstützt."

# ---------- Logging / Clean screen ----------
mkdir -p "$(dirname "$LOGFILE")"
exec > >(stdbuf -oL tee -a "$LOGFILE") 2>&1
[[ -z "$NO_CLEAR" ]] && echo -ne "\033c"  # Clear Screen optional
info "Logfile: $LOGFILE"
info "Erkannt: ${PRETTY_NAME:-$OS} ($CODENAME) – Arch: $(dpkg --print-architecture)"

# ---------- 1) Konfliktpakete entfernen ----------
info "Entferne evtl. konfliktierende Pakete…"
apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || true

# ---------- 2) Docker-Repo einrichten ----------
info "Richte offizielles Docker-Repository ein…"
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings

# Key + Checksum laden
TMP_KEY="$(mktemp)"
TMP_SUM="$(mktemp)"
curl -fsSL "https://download.docker.com/linux/$OS/gpg" -o "$TMP_KEY"
curl -fsSL "https://download.docker.com/linux/$OS/gpg.sha256" -o "$TMP_SUM"

# Prüfen
(cd "$(dirname "$TMP_KEY")" && sha256sum -c "$TMP_SUM") || die "GPG-Key Checksum-Verifikation fehlgeschlagen!"

# Installieren
gpg --dearmor -o /etc/apt/keyrings/docker.gpg "$TMP_KEY"
chmod a+r /etc/apt/keyrings/docker.gpg
rm -f "$TMP_KEY" "$TMP_SUM"

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

# ---------- 3) Docker installieren ----------
info "Installiere Docker Engine, CLI, containerd, Buildx & Compose-Plugin…"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ---------- 4) Dienste aktivieren ----------
info "Aktiviere & starte Dienste…"
systemctl enable --now docker.service
systemctl enable --now containerd.service || systemctl enable --now containerd || true

# ---------- 5) Benutzer optional hinzufügen ----------
if [[ -n "$ADD_USER" ]]; then
  if id "$ADD_USER" >/dev/null 2>&1; then
    info "Füge Benutzer '${ADD_USER}' der Gruppe 'docker' hinzu…"
    groupadd docker 2>/dev/null || true
    usermod -aG docker "$ADD_USER"
    warn "Ab-/Anmeldung (oder 'newgrp docker') nötig, damit die Gruppenrechte greifen."
  else
    warn "Benutzer '${ADD_USER}' existiert nicht – überspringe."
  fi
fi

# ---------- 6) Kurztests ----------
docker --version && docker compose version || true
if [[ -z "$NO_HELLO" ]]; then
  info "Kurztest: docker run hello-world…"
  if docker run --rm hello-world >/dev/null 2>&1; then
    echo -e "${GRE}[OK]${END} Docker läuft."
  else
    echo -e "${YEL}[HINW]${END} 'hello-world' schlug fehl – Details im Log prüfen."
  fi
fi

info "Fertig. Viel Spaß mit Docker!"
