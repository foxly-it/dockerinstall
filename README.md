# 🐳 Docker & Docker Compose Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-informational?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/foxly-it/dockerinstall?style=for-the-badge)](https://github.com/foxly-it/dockerinstall/stargazers)
[![Issues](https://img.shields.io/github/issues/foxly-it/dockerinstall?style=for-the-badge)](https://github.com/foxly-it/dockerinstall/issues)
[![Shell Script](https://img.shields.io/badge/language-Bash-blue?style=for-the-badge)](#)
[![Made by Foxly](https://img.shields.io/badge/made%20by-Foxly%20IT-orange?style=for-the-badge)](https://foxly.de)

---

## 🧩 Übersicht

Minimalistische, aber robuste **Bash-Skripte** zum Installieren **und** sauberen Entfernen von  
[Docker Engine](https://docs.docker.com/engine/) + [Docker Compose v2](https://docs.docker.com/compose/).

Getestet auf:

- 🐧 **Debian 12 (Bookworm)** & **Debian 13 (Trixie)**
- 🟣 **Ubuntu 24.04 LTS (Noble)**

---

## ✨ Features

- Entfernt automatisch alte/conflicting Docker-/containerd-Pakete  
- Richtet das **offizielle Docker-Repository** ein (GPG-Key mit SHA256-Verifikation)  
- Installiert **Docker Engine**, **CLI**, **Buildx** & **Compose Plugin**  
- Aktiviert & startet benötigte systemd-Services  
- Optional: fügt Benutzer der Gruppe `docker` hinzu  
- Saubere **Deinstallation** inkl. Option zum Beibehalten der Daten  

---

## 🚀 Installation

    # Repository klonen
    git clone https://github.com/foxly-it/dockerinstall.git
    cd dockerinstall

    # Installer starten (interaktiv)
    sudo ./install.sh

Nach Abschluss prüfen:

    docker --version
    docker compose version

---

## ⚙️ Installationsoptionen

    sudo ./install.sh [OPTIONS]

| Option | Beschreibung |
|--------|---------------|
| `--add-user USER` | Fügt *USER* der `docker`-Gruppe hinzu |
| `--no-hello` | Überspringt den Hello-World-Test |
| `--no-clear` | Terminal nicht löschen |
| `--log-file=/pfad/datei.log` | Individueller Logpfad |

> ⚠️ **Achtung:** Mitglieder der `docker`-Gruppe besitzen **root-ähnliche Rechte**. Nur vertrauenswürdigen Accounts hinzufügen.

---

## 🗑️ Deinstallation

    sudo ./uninstall.sh [OPTIONS]

| Option | Beschreibung |
|--------|---------------|
| `--keep-data` | Behält `/var/lib/docker` & `/var/lib/containerd` |
| `--no-clear` | Terminal nicht löschen |
| `--log-file=/pfad/datei.log` | Individueller Logpfad |

---

## 🧾 Logging & Sicherheit

- Logs:  
  - `/var/log/docker-install.log`  
  - `/var/log/docker-uninstall.log`
- Der Docker-GPG-Key wird **per SHA256** validiert, bevor das Repository eingebunden wird.

---

## 🧰 Troubleshooting

| Problem | Lösung |
|----------|--------|
| **GPG/Repo-Fehler** | Stelle sicher, dass `ca-certificates`, `curl`, `gnupg` installiert sind |
| **Konflikt-Pakete** | Alte `docker.io`/`containerd` Pakete werden entfernt — Installer erneut ausführen |
| **Service startet nicht** | `systemctl status docker` prüfen und Log unter `/var/log/docker-install.log` ansehen |

---

## 🧪 Getestete Distributionen

| Distribution | Status | Anmerkung |
|---------------|---------|-----------|
| Debian 12 (Bookworm) | ✅ | vollständig getestet |
| Debian 13 (Trixie) | ✅ | vollständig getestet |
| Ubuntu 24.04 LTS (Noble) | ✅ | vollständig getestet |
| Andere (z. B. Mint, Kali, Pop!\_OS) | ⚙️ | ungetestet, sollte aber funktionieren |

---

## 🤝 Mitwirken

Pull Requests & Issues sind willkommen!  
Vorschläge zu neuen Features, zusätzlichen Distros oder Verbesserungen der Logik bitte im [Issue-Tracker](https://github.com/foxly-it/dockerinstall/issues) melden.

---

## 🛡️ Sicherheitshinweis

Für produktive Umgebungen lies bitte zusätzlich die offiziellen  
[Docker Security Best Practices](https://docs.docker.com/security/).  
Denke daran: Mitglieder der Gruppe `docker` besitzen **root-ähnliche Rechte**!

---

## 📜 Lizenz

Dieses Projekt steht unter der **MIT License**.  
Details siehe [LICENSE](LICENSE).

---
