# 🐳 Foxly dockerinstall — Docker Installer, Upgrader & Uninstaller

[🇩🇪 Deutsch](#-deutsch) | [🇬🇧 English](#-english)

[![License: MIT](https://img.shields.io/badge/License-MIT-informational?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/foxly-it/dockerinstall?style=for-the-badge)](https://github.com/foxly-it/dockerinstall/stargazers)
[![Issues](https://img.shields.io/github/issues/foxly-it/dockerinstall?style=for-the-badge)](https://github.com/foxly-it/dockerinstall/issues)
![Bash](https://img.shields.io/badge/language-Bash-blue?style=for-the-badge)
[![Made by Foxly](https://img.shields.io/badge/made%20by-Foxly%20IT-orange?style=for-the-badge)](https://foxly.de)

---

## 🇩🇪 Deutsch

### 🧩 Übersicht

**dockerinstall.sh** ist ein eigenständiges **Single-File-Tool zur Verwaltung von Docker** auf Linux-Systemen.

Es deckt den kompletten Lebenszyklus ab:

- Installation von Docker Engine & Plugins  
- sauberes Upgrade bestehender Installationen  
- vollständige Deinstallation (optional inkl. Daten)  
- integrierter Self-Check und Backup-Funktion  
- interaktive **und** nicht-interaktive Nutzung  

Kein Framework, keine Abhängigkeiten – **ein Skript, volle Kontrolle**.

---

### 🖥️ Unterstützte Systeme

Getestet und produktiv genutzt auf:

- Debian 12 (Bookworm)
- Debian 13 (Trixie)
- Ubuntu 22.04 / 24.04 LTS

Distribution und Codename werden automatisch über `/etc/os-release` erkannt.

---

### ✨ Features (v2.x)

**Installation**
- entfernt alte oder konfliktbehaftete Docker-Pakete
- richtet das offizielle Docker-APT-Repository inkl. GPG-Key ein
- installiert Docker Engine, CLI, Buildx & Compose Plugin
- aktiviert systemd-Dienste
- optional: Benutzer zur `docker`-Gruppe hinzufügen

**Upgrade**
- prüft und repariert Repository-Konfiguration
- reinstalliert Docker & Plugins sauber
- optional: Backup, Force-Upgrade, non-interactive

**Uninstall**
- entfernt Docker-Pakete, Repo & GPG-Keys
- optional: Docker-Daten behalten oder löschen
- systemd-Bereinigung

**Self-Check**
- Root-Rechte
- APT-Status & Locks
- curl / gpg
- systemd
- Schreibrechte unter `/var/lib`
- Docker-Status

**Backup**
- `.tar.gz`-Backup von:
  - `/var/lib/docker`
  - `/var/lib/containerd`


---

### 🚀 Nutzung

Repository klonen:

    git clone https://github.com/foxly-it/dockerinstall.git
    cd dockerinstall

Interaktiv starten:

    sudo ./dockerinstall.sh

Menü:

    1) Installieren
    2) Upgrade
    9) Deinstallieren

---

### ⚙️ CLI-Modus & Optionen

    sudo ./dockerinstall.sh [install|upgrade|uninstall] [OPTIONS]

Optionen:

    --add-user=USER        Benutzer zur docker-Gruppe hinzufügen
    --no-hello             Hello-World-Test überspringen
    --no-clear             Terminal nicht löschen
    --log-file=PATH        Eigenen Logpfad setzen
    --non-interactive      Keine Prompts, kein Menü
    --backup-data          Backup vor Upgrade/Uninstall
    --force-upgrade        Upgrade erzwingen
    --self-check           Nur Systemcheck ausführen

Beispiele:

    sudo ./dockerinstall.sh install --no-hello
    sudo ./dockerinstall.sh upgrade --backup-data --non-interactive

---

### 🧾 Logging

    /var/log/docker-install.log
    /var/log/docker-uninstall.log

---

### 🛡️ Sicherheit

Mitglieder der `docker`-Gruppe besitzen **root-ähnliche Rechte**.  
Nur vertrauenswürdige Benutzer hinzufügen.

Docker Security Best Practices:  
https://docs.docker.com/security/

---

## 🇬🇧 English

### 🧩 Overview

**dockerinstall.sh** is a standalone **single-file tool for managing Docker** on Linux systems.

It covers the complete Docker lifecycle:

- installation of Docker Engine & plugins  
- clean upgrades of existing installations  
- full removal (optionally including data)  
- integrated self-check and backup  
- interactive **and** non-interactive operation  

No frameworks, no dependencies — **one script, full control**.

---

### 🖥️ Supported Systems

Tested and used in production on:

- Debian 12 (Bookworm)
- Debian 13 (Trixie)
- Ubuntu 22.04 / 24.04 LTS

Distribution and codename are detected automatically via `/etc/os-release`.

---

### ✨ Features (v2.x)

**Installation**
- removes conflicting Docker packages
- sets up the official Docker APT repository incl. GPG key
- installs Docker Engine, CLI, Buildx & Compose plugin
- enables systemd services
- optional docker group user setup

**Upgrade**
- verifies and fixes repository configuration
- clean reinstall of Docker & plugins
- optional backup, force-upgrade, non-interactive mode

**Uninstall**
- removes Docker packages, repo and GPG keys
- optional data removal
- systemd cleanup

**Self-Check**
- root privileges
- APT status & locks
- curl / gpg
- systemd
- write access under `/var/lib`
- Docker status

**Backup**
- creates a `.tar.gz` backup of:
  - `/var/lib/docker`
  - `/var/lib/containerd`


---

### 🚀 Usage

Clone the repository:

    git clone https://github.com/foxly-it/dockerinstall.git
    cd dockerinstall

Run interactively:

    sudo ./dockerinstall.sh

---

### ⚙️ CLI Mode & Options

    sudo ./dockerinstall.sh [install|upgrade|uninstall] [OPTIONS]

---

### 🛡️ Security Note

Members of the `docker` group have **root-like privileges**.  
Only add trusted users.

---

## 📜 License

MIT License  
See [LICENSE](LICENSE).

---

Foxly IT  
Reboot required — but planned.

![Alt](https://repobeats.axiom.co/api/embed/49f262ca5e7653bb4718e0b5c55547018a7ce48b.svg "Repobeats analytics image")
