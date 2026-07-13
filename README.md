# 🐳 Foxly dockerinstall

Single-file manager for installing, upgrading, checking, backing up, and uninstalling Docker Engine on supported Debian and Ubuntu hosts.

[Deutsch](#deutsch) · [English](#english) · [MIT License](LICENSE)

## Deutsch

### Unterstützte Systeme

- Debian 11 (Bullseye), 12 (Bookworm) und 13 (Trixie)
- Ubuntu 22.04 LTS, 24.04 LTS, 25.10 und 26.04 LTS
- systemd und eine von Docker unterstützte Architektur

Der Installer lehnt nicht unterstützte Distributionen und Versionen ab. Der Support-Stand orientiert sich an den offiziellen Anleitungen für [Debian](https://docs.docker.com/engine/install/debian/) und [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

### Eigenschaften

- offizielles Docker-APT-Repository im aktuellen Deb822-Format (`docker.sources`)
- offizieller Docker-Signaturschlüssel (`docker.asc`)
- Docker Engine, CLI, containerd, Buildx und Compose v2
- sichere, validierte CLI für interaktive und automatisierte Nutzung
- getrennte Logs für Installation, Self-Check und Deinstallation
- optionales Host-Backup bei angehaltenem Docker-Dienst
- Datenlöschung nur nach explizitem `--remove-data` oder Bestätigung

> Mitglieder der Gruppe `docker` besitzen root-ähnliche Rechte. Füge nur vertrauenswürdige Benutzer hinzu.

### Installation

```bash
git clone https://github.com/foxly-it/dockerinstall.git
cd dockerinstall
sudo ./dockerinstall.sh install
```

Interaktives Menü:

```bash
sudo ./dockerinstall.sh
```

Automatisierte Installation:

```bash
sudo ./dockerinstall.sh install --non-interactive --no-hello
```

### Upgrade

```bash
sudo ./dockerinstall.sh upgrade
sudo ./dockerinstall.sh upgrade --backup-data
sudo ./dockerinstall.sh upgrade --force-upgrade
```

Ohne `--force-upgrade` aktualisiert APT nur Pakete, für die eine neuere Version verfügbar ist. Mit der Option werden die Docker-Pakete zusätzlich reinstalliert.

### Deinstallation

Docker-Pakete entfernen und Daten behalten:

```bash
sudo ./dockerinstall.sh uninstall --non-interactive
```

Vorher sichern und Daten anschließend ausdrücklich löschen:

```bash
sudo ./dockerinstall.sh uninstall --backup-data --remove-data --non-interactive
```

`--backup-data` löscht niemals automatisch Daten. Ohne `--remove-data` bleiben `/var/lib/docker` und `/var/lib/containerd` erhalten.

### Optionen

```text
--add-user=USER       USER zur docker-Gruppe hinzufügen
--add-user USER       Alternative Schreibweise
--no-hello            hello-world-Prüfung überspringen
--no-clear            Terminal nicht leeren
--no-color            Farben deaktivieren
--log-file=PATH       eigenen Logpfad verwenden
--non-interactive     niemals Eingaben abfragen
--backup-data         gestopptes Host-Backup erstellen
--remove-data         Docker-Daten bei uninstall löschen
--keep-data           Docker-Daten bei uninstall behalten (Standard)
--force-upgrade       Docker-Pakete beim Upgrade reinstallieren
--self-check          System nur prüfen
-h, --help            Hilfe anzeigen
--version             Skriptversion anzeigen
```

### Backup-Hinweis

Das Backup archiviert vorhandene Verzeichnisse unter `/var/lib/docker`, `/var/lib/containerd` und `/etc/docker` nach `/var/backups`. Docker und containerd werden dafür kurz angehalten und anschließend wieder gestartet, falls Docker vorher lief.

Das ist ein Host-Level-Notfallbackup. Für Datenbanken und produktive Anwendungen sollten zusätzlich anwendungskonsistente Dumps und getestete Volume-Backups verwendet werden. Bind-Mount-Daten außerhalb dieser Pfade sind nicht enthalten.

### Logs

- Installation und Upgrade: `/var/log/docker-install.log`
- Deinstallation: `/var/log/docker-uninstall.log`
- Self-Check: `/var/log/docker-self-check.log`

### Entwicklung und Tests

```bash
bash -n dockerinstall.sh
bash tests/integration.sh
shellcheck dockerinstall.sh tests/integration.sh tests/mock-command.sh
```

Die Integrationstests verwenden einen isolierten Test-Root und gemockte Systembefehle. Sie verändern weder Docker noch APT auf dem Entwicklungsrechner. Ein Release sollte zusätzlich auf frischen VMs aller als getestet ausgewiesenen Distributionen geprüft werden.

## English

### Supported systems

- Debian 11 (Bullseye), 12 (Bookworm), and 13 (Trixie)
- Ubuntu 22.04 LTS, 24.04 LTS, 25.10, and 26.04 LTS
- systemd and a Docker-supported architecture

The installer rejects unsupported distributions and releases. The support matrix follows Docker's official installation documentation for [Debian](https://docs.docker.com/engine/install/debian/) and [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

### Features

- Docker's official APT repository using the current Deb822 format (`docker.sources`)
- Docker's official signing key (`docker.asc`)
- Docker Engine, CLI, containerd, Buildx, and Compose v2
- safe, validated CLI for interactive and automated operation
- separate logs for installation, self-check, and uninstallation
- optional host-level backup while the Docker service is stopped
- data removal only after an explicit `--remove-data` option or confirmation

> Membership in the `docker` group grants root-level privileges. Only add trusted users.

### Installation

```bash
git clone https://github.com/foxly-it/dockerinstall.git
cd dockerinstall
sudo ./dockerinstall.sh install
```

Open the interactive menu:

```bash
sudo ./dockerinstall.sh
```

Run an automated installation:

```bash
sudo ./dockerinstall.sh install --non-interactive --no-hello
```

### Upgrade

```bash
sudo ./dockerinstall.sh upgrade
sudo ./dockerinstall.sh upgrade --backup-data
sudo ./dockerinstall.sh upgrade --force-upgrade
```

Without `--force-upgrade`, APT only updates packages for which a newer version is available. With this option, the Docker packages are reinstalled as well.

### Uninstallation

Remove Docker packages while retaining all Docker data:

```bash
sudo ./dockerinstall.sh uninstall --non-interactive
```

Create a backup first and then explicitly remove the data:

```bash
sudo ./dockerinstall.sh uninstall --backup-data --remove-data --non-interactive
```

`--backup-data` never removes data automatically. Unless `--remove-data` is supplied, `/var/lib/docker` and `/var/lib/containerd` are retained.

### Options

```text
--add-user=USER       Add USER to the docker group
--add-user USER       Alternative syntax
--no-hello            Skip the hello-world verification
--no-clear            Do not clear the terminal
--no-color            Disable colored output
--log-file=PATH       Use a custom log file
--non-interactive     Never prompt for input
--backup-data         Create a stopped host-level backup
--remove-data         Remove Docker data during uninstall
--keep-data           Retain Docker data during uninstall (default)
--force-upgrade       Reinstall Docker packages during upgrade
--self-check          Validate the system without installing anything
-h, --help            Show command help
--version             Show the script version
```

### Backup notes

The backup archives existing directories under `/var/lib/docker`, `/var/lib/containerd`, and `/etc/docker` to `/var/backups`. Docker and containerd are stopped briefly and started again afterward if Docker was running before the backup.

This is an emergency host-level backup. Databases and production applications should additionally use application-consistent dumps and tested volume backups. Bind-mounted data outside the listed paths is not included.

### Logs

- Installation and upgrade: `/var/log/docker-install.log`
- Uninstallation: `/var/log/docker-uninstall.log`
- Self-check: `/var/log/docker-self-check.log`

### Development and testing

```bash
bash -n dockerinstall.sh
bash tests/integration.sh
shellcheck dockerinstall.sh tests/integration.sh tests/mock-command.sh
```

The integration tests use an isolated test root and mocked system commands. They do not modify Docker or APT on the development machine. Before publishing a release, the complete workflow should additionally be tested on clean virtual machines for every distribution advertised as tested.

Run `./dockerinstall.sh --help` to display the built-in command reference.

## License

[MIT](LICENSE) © Foxly IT

![Alt](https://repobeats.axiom.co/api/embed/49f262ca5e7653bb4718e0b5c55547018a7ce48b.svg "Repobeats analytics image")
