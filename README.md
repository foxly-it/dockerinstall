# 🐳 Foxly dockerinstall – Docker Installer, Upgrader & Uninstaller

[![License: MIT](https://img.shields.io/badge/License-MIT-informational?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/foxly-it/dockerinstall?style=for-the-badge)](https://github.com/foxly-it/dockerinstall/stargazers)
[![Issues](https://img.shields.io/github/issues/foxly-it/dockerinstall?style=for-the-badge)](https://github.com/foxly-it/dockerinstall/issues)
![Bash](https://img.shields.io/badge/language-Bash-blue?style=for-the-badge)
[![Made by Foxly](https://img.shields.io/badge/made%20by-Foxly%20IT-orange?style=for-the-badge)](https://foxly.de)

---

## 🧩 Übersicht

**dockerinstall.sh** ist ein komplett eigenständiges **Single-File Docker Management Tool**:

- Installiert Docker Engine + CLI + Buildx + Compose
- Führt ein **Upgrade** durch (Repo fix + Reinstall)
- Entfernt Docker vollständig (inkl. optionaler Daten)
- Integrierte:
  - **Backup-Funktion**  
  - **Self-Check**  
  - **Repo-Korrektur**  
  - **TTY-Optimierte Visuals (ASCII-Fox + Progressbar)**  
  - **Nicht-Interaktiver Modus für Skripte und Automationen**

Getestet auf:

- 🐧 **Debian 12 (Bookworm)**  
- 🐧 **Debian 13 (Trixie)**  
- 🟪 **Ubuntu 22.04+ / 24.04 LTS**

Das Script erkennt Distribution & Codename automatisch über `/etc/os-release`.

---

## ✨ Features (v2.x)

### ⚙️ Installation
- Entfernt alte/conflicting Docker-Pakete (`docker.io`, alte Compose, containerd Varianten)
- Richtet **offizielles Docker-Repo inkl. GPG-Key** ein
- Installiert:
  - `docker-ce`
  - `docker-ce-cli`
  - `containerd.io`
  - `docker-buildx-plugin`
  - `docker-compose-plugin`
- Aktiviert systemd-Dienste
- Optional: fügt Benutzer der `docker`-Gruppe hinzu

### 🔧 Upgrade
- Überprüft Repository und korrigiert es (Debian/Ubuntu-aware)
- Reinstalliert Docker + Plugins sauber
- Erneuert Dienste
- Optional: `--backup-data` vorher
- Optional: `--force-upgrade`

### 🗑️ Uninstall
- Entfernt alle Docker-Pakete
- Entfernt Repository + GPG-Key
- Optional: Daten löschen oder behalten
- Bereinigt systemd

### 🧪 Self-Check
`--self-check` prüft u. a.:

- root-Rechte  
- apt-System  
- curl / gpg  
- systemd  
- APT-Lock  
- Schreibrechte unter `/var/lib`  
- Docker-Status  

### 📦 Backup
`--backup-data` erzeugt ein `.tar.gz`-Backup aus:

- `/var/lib/docker`
- `/var/lib/containerd`

### 💻 TTY-optimierte Visuals
- Foxly-ASCII-Art  
- ruhige Bubble-Animation  
- Mini-Progressbar mit dynamischer Breite  
- compose-pull-3-Line-View  

---

## 🚀 Nutzung

### 📥 Klonen

```bash
git clone https://github.com/foxly-it/dockerinstall.git
cd dockerinstall
```

### ▶️ Starten (interaktiv)

```bash
sudo ./dockerinstall.sh
```

Du bekommst ein Menü:

```
1) Installieren
2) Upgrade
9) Deinstallieren
```

---

## ⚙️ Optionen

### Allgemein

```bash
sudo ./dockerinstall.sh [install|upgrade|uninstall] [OPTIONS]
```

### Optionen im Detail

| Option | Beschreibung |
|--------|--------------|
| `--add-user=USER` | Fügt USER zur `docker`-Gruppe hinzu |
| `--no-hello` | Überspringt den Hello-World-Test |
| `--no-clear` | Terminal nicht löschen |
| `--log-file=/pfad/log.txt` | Logpfad setzen |
| `--non-interactive` | Kein Menü, keine Prompts |
| `--backup-data` | Vor Upgrade/Uninstall Backup erstellen |
| `--force-upgrade` | Auch upgraden, wenn Repo ok / Version identisch |
| `--self-check` | Führt nur den Systemcheck aus |

### Beispiele

Installation ohne Hello-World:

```bash
sudo ./dockerinstall.sh install --no-hello
```

Upgrade + Backup + non-interactive:

```bash
sudo ./dockerinstall.sh upgrade --backup-data --non-interactive
```

---

## 🗑️ Deinstallation

```bash
sudo ./dockerinstall.sh uninstall
```

Mit Entfernen aller Daten:

```bash
sudo ./dockerinstall.sh uninstall --backup-data --non-interactive
```

---

## 🧾 Logging

Alle Aktionen werden protokolliert:

- `/var/log/docker-install.log`
- `/var/log/docker-uninstall.log`

---

## 🧰 Troubleshooting

| Problem | Mögliche Lösung |
|---------|------------------|
| GPG/Repo-Fehler | Internet prüfen, `ca-certificates curl gnupg` installieren |
| Konflikt-Pakete | Script entfernt sie automatisch – nochmal ausführen |
| Docker startet nicht | `systemctl status docker`, Log prüfen |
| Upgrade passiert nicht | Menü gewählt? → ggf. `--force-upgrade` nutzen |

---

## 🧪 Unterstützte Distributionen

| Distribution | Status | Hinweis |
|--------------|--------|---------|
| Debian 12 | ✅ | vollständig getestet |
| Debian 13 | ✅ | vollständig getestet |
| Ubuntu 22.04+ | ✅ | vollständig getestet |
| Mint / Pop!\_OS / Kali | ⚙️ | sollte funktionieren, aber ungetestet |

---

## 🤝 Mitwirken

PRs & Issues sind willkommen!  
Feature-Wünsche, Bugreports oder Ideen gern hier melden:

👉 https://github.com/foxly-it/dockerinstall/issues

---

## 🛡️ Sicherheit

Docker-Benutzer besitzen **root-ähnliche Rechte**.  
Nur vertrauenswürdige Accounts der Gruppe `docker` hinzufügen.

Offizielle Docker Security Best Practices:  
https://docs.docker.com/security/

---

## 📜 Lizenz

Dieses Projekt steht unter **MIT License**.  
Siehe [LICENSE](LICENSE).

---
