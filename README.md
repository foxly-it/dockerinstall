# Foxly dockerinstall

`dockerinstall.sh` is a standalone command-line tool for installing, upgrading, validating, backing up, and uninstalling Docker Engine on supported Debian and Ubuntu systems.

The project uses Docker's official APT repository and provides both interactive operation and predictable non-interactive workflows for automated system provisioning.

[Deutsche Dokumentation](#deutsche-dokumentation) | [English documentation](#english-documentation) | [License](#license)

## Deutsche Dokumentation

### Überblick

Das Skript verwaltet den vollständigen Docker-Lebenszyklus in einer einzelnen ausführbaren Datei. Es validiert Betriebssystem und Kommandozeilenargumente, richtet das offizielle Docker-Repository ein und prüft die Installation nach Abschluss.

Zum installierten Umfang gehören:

- Docker Engine und Docker CLI
- containerd
- Docker Buildx
- Docker Compose v2
- systemd-Servicekonfiguration

### Systemanforderungen

| Distribution | Unterstützte Versionen |
| --- | --- |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |
| Ubuntu | 22.04 LTS, 24.04 LTS, 25.10, 26.04 LTS |

Zusätzlich erforderlich sind:

- systemd
- eine von Docker unterstützte Architektur
- Root-Rechte über `root` oder `sudo`
- Internetzugriff auf die Paketquellen von Debian beziehungsweise Ubuntu und Docker

Nicht unterstützte Distributionen und Versionen werden vor Änderungen am Paketsystem abgelehnt. Die Support-Matrix orientiert sich an den offiziellen Docker-Anleitungen für [Debian](https://docs.docker.com/engine/install/debian/) und [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

### Funktionsumfang

- Docker-APT-Repository im Deb822-Format unter `/etc/apt/sources.list.d/docker.sources`
- offizieller Docker-Signaturschlüssel unter `/etc/apt/keyrings/docker.asc`
- Erkennung und Entfernung konfliktbehafteter Pakete
- validierte interaktive und nicht-interaktive Ausführung
- getrennte Protokolle für Installation, Self-Check und Deinstallation
- optionales Host-Level-Backup bei angehaltenen Docker-Diensten
- explizite Bestätigung vor dem Löschen persistenter Docker-Daten
- abschließende Prüfung von Docker Engine, Compose, Buildx und Docker-Daemon

### Installation

Repository klonen und Installation starten:

```bash
git clone https://github.com/foxly-it/dockerinstall.git
cd dockerinstall
sudo ./dockerinstall.sh install
```

Interaktives Hauptmenü öffnen:

```bash
sudo ./dockerinstall.sh
```

Nicht-interaktive Installation ohne `hello-world`-Test:

```bash
sudo ./dockerinstall.sh install --non-interactive --no-hello
```

### Upgrade

Standard-Upgrade über APT:

```bash
sudo ./dockerinstall.sh upgrade
```

Upgrade mit vorherigem Host-Level-Backup:

```bash
sudo ./dockerinstall.sh upgrade --backup-data
```

Erzwungene Reinstallation der Docker-Pakete:

```bash
sudo ./dockerinstall.sh upgrade --force-upgrade
```

Ohne `--force-upgrade` aktualisiert APT nur Pakete, für die eine neuere Version verfügbar ist.

### Deinstallation

Docker-Pakete entfernen und persistente Daten behalten:

```bash
sudo ./dockerinstall.sh uninstall --non-interactive
```

Vor der Deinstallation ein Backup erstellen und die Daten anschließend ausdrücklich löschen:

```bash
sudo ./dockerinstall.sh uninstall --backup-data --remove-data --non-interactive
```

Die Option `--backup-data` führt niemals automatisch zu einer Datenlöschung. Ohne `--remove-data` bleiben `/var/lib/docker` und `/var/lib/containerd` erhalten.

### Kommandozeilenreferenz

| Option | Beschreibung |
| --- | --- |
| `--add-user=USER` | Fügt `USER` zur Gruppe `docker` hinzu |
| `--add-user USER` | Alternative Schreibweise für `--add-user` |
| `--no-hello` | Überspringt die `hello-world`-Prüfung |
| `--no-clear` | Leert das Terminal beim Start nicht |
| `--no-color` | Deaktiviert farbige Ausgabe |
| `--log-file=PATH` | Verwendet eine benutzerdefinierte Logdatei |
| `--non-interactive` | Deaktiviert sämtliche Eingabeaufforderungen |
| `--backup-data` | Erstellt ein Host-Level-Backup bei angehaltenen Diensten |
| `--remove-data` | Löscht Docker-Daten bei der Deinstallation |
| `--keep-data` | Behält Docker-Daten bei der Deinstallation; Standardverhalten |
| `--force-upgrade` | Reinstalliert Docker-Pakete während des Upgrades |
| `--self-check` | Prüft das System, ohne Docker zu installieren |
| `-h`, `--help` | Zeigt die integrierte Hilfe an |
| `--version` | Zeigt die Skriptversion an |

### Sicherheit und Datensicherung

Mitglieder der Gruppe `docker` besitzen root-ähnliche Rechte. Nur vertrauenswürdige Benutzer sollten dieser Gruppe hinzugefügt werden.

Das Host-Level-Backup archiviert vorhandene Daten aus `/var/lib/docker`, `/var/lib/containerd` und `/etc/docker` nach `/var/backups`. Docker und containerd werden dafür vorübergehend angehalten und anschließend wieder gestartet, sofern Docker zuvor aktiv war.

Dieses Backup ist als administratives Notfall-Backup vorgesehen. Für Datenbanken und produktive Anwendungen sind zusätzlich anwendungskonsistente Dumps und getestete Volume-Backups erforderlich. Daten aus Bind-Mounts außerhalb der genannten Verzeichnisse sind nicht enthalten.

### Protokolldateien

| Vorgang | Standardpfad |
| --- | --- |
| Installation und Upgrade | `/var/log/docker-install.log` |
| Deinstallation | `/var/log/docker-uninstall.log` |
| Self-Check | `/var/log/docker-self-check.log` |

### Entwicklung und Tests

```bash
bash -n dockerinstall.sh tests/integration.sh tests/mock-command.sh
bash tests/integration.sh
shellcheck dockerinstall.sh tests/integration.sh tests/mock-command.sh
```

Die Integrationstests verwenden ein isoliertes Test-Root und simulierte Systembefehle. Sie verändern weder Docker noch APT auf dem Entwicklungsrechner. Vor einer Veröffentlichung sollte der vollständige Ablauf zusätzlich auf frischen virtuellen Maschinen für alle als getestet ausgewiesenen Distributionen geprüft werden.

## English documentation

### Overview

The script manages the complete Docker lifecycle from a single executable file. It validates the operating system and command-line arguments, configures Docker's official repository, and verifies the resulting installation.

The installed components include:

- Docker Engine and Docker CLI
- containerd
- Docker Buildx
- Docker Compose v2
- systemd service configuration

### System requirements

| Distribution | Supported releases |
| --- | --- |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |
| Ubuntu | 22.04 LTS, 24.04 LTS, 25.10, 26.04 LTS |

Additional requirements:

- systemd
- an architecture supported by Docker
- root privileges through `root` or `sudo`
- network access to the Debian or Ubuntu package repositories and Docker's package repository

Unsupported distributions and releases are rejected before the package system is modified. The support matrix follows Docker's official installation documentation for [Debian](https://docs.docker.com/engine/install/debian/) and [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

### Features

- Docker APT repository in Deb822 format at `/etc/apt/sources.list.d/docker.sources`
- official Docker signing key at `/etc/apt/keyrings/docker.asc`
- detection and removal of conflicting packages
- validated interactive and non-interactive operation
- separate logs for installation, self-check, and uninstallation
- optional host-level backup while Docker services are stopped
- explicit confirmation before persistent Docker data is removed
- post-installation validation of Docker Engine, Compose, Buildx, and the Docker daemon

### Installation

Clone the repository and start the installation:

```bash
git clone https://github.com/foxly-it/dockerinstall.git
cd dockerinstall
sudo ./dockerinstall.sh install
```

Open the interactive main menu:

```bash
sudo ./dockerinstall.sh
```

Run a non-interactive installation without the `hello-world` test:

```bash
sudo ./dockerinstall.sh install --non-interactive --no-hello
```

### Upgrade

Standard upgrade through APT:

```bash
sudo ./dockerinstall.sh upgrade
```

Create a host-level backup before upgrading:

```bash
sudo ./dockerinstall.sh upgrade --backup-data
```

Force reinstallation of all Docker packages:

```bash
sudo ./dockerinstall.sh upgrade --force-upgrade
```

Without `--force-upgrade`, APT only updates packages for which a newer version is available.

### Uninstallation

Remove the Docker packages while retaining persistent data:

```bash
sudo ./dockerinstall.sh uninstall --non-interactive
```

Create a backup before uninstalling and then explicitly remove the data:

```bash
sudo ./dockerinstall.sh uninstall --backup-data --remove-data --non-interactive
```

The `--backup-data` option never removes data automatically. Unless `--remove-data` is supplied, `/var/lib/docker` and `/var/lib/containerd` are retained.

### Command-line reference

| Option | Description |
| --- | --- |
| `--add-user=USER` | Adds `USER` to the `docker` group |
| `--add-user USER` | Alternative syntax for `--add-user` |
| `--no-hello` | Skips the `hello-world` verification |
| `--no-clear` | Does not clear the terminal at startup |
| `--no-color` | Disables colored output |
| `--log-file=PATH` | Uses a custom log file |
| `--non-interactive` | Disables all prompts |
| `--backup-data` | Creates a host-level backup while services are stopped |
| `--remove-data` | Removes Docker data during uninstallation |
| `--keep-data` | Retains Docker data during uninstallation; default behavior |
| `--force-upgrade` | Reinstalls Docker packages during an upgrade |
| `--self-check` | Validates the system without installing Docker |
| `-h`, `--help` | Displays the built-in help |
| `--version` | Displays the script version |

### Security and backups

Membership in the `docker` group grants root-level privileges. Only trusted users should be added to this group.

The host-level backup archives existing data from `/var/lib/docker`, `/var/lib/containerd`, and `/etc/docker` to `/var/backups`. Docker and containerd are stopped temporarily and restarted afterward if Docker was previously active.

This backup is intended as an administrative emergency backup. Databases and production applications also require application-consistent dumps and tested volume backups. Data from bind mounts outside the listed directories is not included.

### Log files

| Operation | Default path |
| --- | --- |
| Installation and upgrade | `/var/log/docker-install.log` |
| Uninstallation | `/var/log/docker-uninstall.log` |
| Self-check | `/var/log/docker-self-check.log` |

### Development and testing

```bash
bash -n dockerinstall.sh tests/integration.sh tests/mock-command.sh
bash tests/integration.sh
shellcheck dockerinstall.sh tests/integration.sh tests/mock-command.sh
```

The integration tests use an isolated test root and simulated system commands. They do not modify Docker or APT on the development machine. Before publishing a release, the complete workflow should also be tested on clean virtual machines for every distribution advertised as tested.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright Foxly IT.

## Repository activity

![Repository activity](https://repobeats.axiom.co/api/embed/49f262ca5e7653bb4718e0b5c55547018a7ce48b.svg "Repobeats repository activity")
