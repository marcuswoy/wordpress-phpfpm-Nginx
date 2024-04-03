# WordPress mit PHP-FPM, Nginx und gültigem Zertifikat über WSL2 Alma-Linux

Diese Anleitung erläutert die Installation von WordPress mit nützlichen Add-ons in einer isolierten WSL-Distribution auf dem eigenen Rechner. Dabei wird gezeigt, wie man eine eigene Domain mit gültigem Zertifikat einrichtet, um SSL-Fehler im Browser zu vermeiden.

**Nach Abschluss der Anleitung sind folgende Bereiche zugänglich:**
- `https://example.com`
- `https://traefik.example.com`
- `https://adminer.example.com`
- `https://logger.example.com`

## Voraussetzungen
- Administrator-Rechte auf einem Windows 11 System mit aktuellen Updates
- Grundkenntnisse in Linux, Podman und Docker Compose
- [mkcert](https://github.com/FiloSottile/mkcert/releases) herunterladen, als `mkcert.exe` umbenennen und in `./system/traefik/certs` ablegen.
- Für Zugriffsschutz eine `.htpasswd` Datei in `./system/traefik/security/` erstellen.

## Automatisierte Änderung
Zwei Powershell-Skripte automatisieren den unten beschriebenen Prozess. Vor dem Ausführen der Skripte bitte in der `.env` Datei im Wurzelverzeichnis die Variable `DOMAIN_NEU` anpassen.

### InstallDependencies.ps1
- Ausführung des Skripts: `.\\InstallDependencies.ps1` in PowerShell.
- Das Terminal muss sich im Wurzelverzeichnis des Projekts befinden.

### ChangeToplevelDomain.ps1
- Das Skript ändert `example.com` in die Wunschdomain.
- Die neue Domain wird in der Datei `.env` als `DOMAIN_NEU` eingetragen.
- Bei Änderungen kann `DOMAIN_NEU` nach `DOMAIN_ALT` verschoben werden.
- Das Skript sucht Übereinstimmungen in `DOMAIN_ALT` und ändert diese in `DOMAIN_NEU`.

## Manuelle Änderung
- Ersetze alle Verweise auf `example.com` durch die gewünschte Domain.

### 1. Zertifikate erstellen
- Navigiere zum Ordner `./system/traefik/certs`.
- Führe aus: `.\\mkcert.exe -cert-file example.com.cert -key-file example.com.key *.example.com example.com www.example.com`
- Führe `mkcert.exe -install` aus und bestätige das Hinzufügen des Zertifikats zu den vertrauenswürdigen Stammzertifikaten.
- Gehe zu `/system/traefik/rules` und passe in `certificates.toml` den Namen des Zertifikats an.

### 2. Hosts-Datei bearbeiten
- Füge folgende Zeilen zur Datei `hosts` hinzu:
    ```
    127.0.0.1 example.com
    127.0.0.1 traefik.example.com
    127.0.0.1 adminer.example.com
    127.0.0.1 logger.example.com
    ```

### 3. AlmaLinux installieren
- Lade [AlmaLinux 9](https://apps.microsoft.com/detail/9p5rwlm70sn9) aus dem Windows Store herunter und installiere es.
- Logge dich nach der Installation mit `wsl -d AlmaLinuxOS-9` ein und führe `dnf update` aus.

### 4. Installation von Podman und Docker Compose
- Installiere Podman: `dnf install -y podman podman-docker`
- Installiere Docker Compose:
    ```
    curl -L "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
    ```
- Überprüfe die Installationen mit `docker-compose -v` und `podman -v`.

### 5. Systemd aktivieren
- Bearbeite `/etc/wsl.conf` mit `nano` und füge hinzu:
    ```
    [boot]
    systemd=true
    ```
- Beende AlmaLinux und starte neu mit `wsl --shutdown`. Logge dich dann mit `wsl -d AlmaLinuxOS-9` ein.
- Überprüfe die Aktivierung von systemd mit `systemctl list-units --type=service`.

### 6. Kommunikation zwischen Podman und Docker Compose
1. Starte Podman Socket: `systemctl start podman.socket`.
2. Aktiviere automatisches Starten: `systemctl enable podman.socket`.
3. Teste den Podman Socket: `curl -H "Content-Type: application/json" --unix-socket /var/run/docker.sock http://localhost/_ping`.

## Projektübertragung
- Übertrage das Projekt direkt in die Distribution oder binde es mittels Visual Studio Code und der Option "WSL: Reopen in WSL" ein.

## Reverse Proxy anpassen
- Gehe zu `/system/.env` und passe die Variable `DOMAINNAME` an.

## Website-Konfiguration
- Nimm Anpassungen an Nginx, PHP-FPM, der Datenbank und WordPress vor.

### Allgemeine Anpassungen
1. Ändere den Ordnernamen in `/websites/example.com` auf die gewünschte Domain.
2. Passe den Dateinamen in `/websites/example.com/prod/system/nginx/sites` an.
3. Ändere `DOMAINNAME` und `DB_PASSWORD` in `/websites/example.com/.env`.

### Nginx anpassen
- Öffne `/websites/example.com/prod/system/nginx/sites/example.com.conf`.
- Ersetze `example.com` durch die gewünschte Domain in den folgenden Zeilen:
    - `return 301 https://example.com$request_uri;`
    - `server_name example.com;`
    - `access_log /var/log/nginx/example.com-access.log;`
    - `error_log /var/log/nginx/example.com-error.log;`

## Anwendungsstart
- Überprüfe vor dem Start der Anwendung die Verfügbarkeit neuerer PHP-Versionen.
1. Erstelle das Netzwerk: `docker network create web`.
2. Gehe in `./system/` und starte den Reverse Proxy: `docker-compose up -d`.
3. Navigiere zu `./websites`, lade WordPress herunter und lege es in `./websites/example.com/prod/data` ab.
4. Starte die Anwendung: `docker-compose up -d`.
5. Öffne `adminer.example.com` und logge dich ein.
6. Erstelle eine Datenbank und folge der WordPress-Installationsanleitung.
7. Öffne nach der Installation `/websites/example.com/prod/data/wp-config.php` und füge hinzu:
    ```php
    if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
        $_SERVER['HTTPS'] = 'on';
    }
    ```
