# Dokumentation: Dieses Skript automatisiert die Installation und Konfiguration von AlmaLinux, Podman und Docker Compose in einer WSL-Umgebung unter Windows.

Write-Host "Skript gestartet..."

# Schritt 3: AlmaLinux Installation
# Hinweis: Die Installation von AlmaLinux aus dem Windows Store muss manuell erfolgen.

# Einloggen in AlmaLinux und Update ausführen
Write-Host "Einloggen in AlmaLinux und Update durchführen..."
wsl -d AlmaLinuxOS-9 -e sudo dnf update -y

# Schritt 4: Installation von Podman und Docker Compose
Write-Host "Installation von Podman und Docker Compose..."

# Podman installieren
wsl -d AlmaLinuxOS-9 -e sudo dnf install -y podman podman-docker

# Docker Compose installieren
$dockerComposeInstallCommand = "curl -L https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose"
wsl -d AlmaLinuxOS-9 -e bash -c $dockerComposeInstallCommand


# Systemd aktivieren
$systemdConfigCommand = "echo '[boot]`nsystemd=true' | sudo tee /etc/wsl.conf"
wsl -d AlmaLinuxOS-9 -e bash -c $systemdConfigCommand
wsl -d AlmaLinuxOS-9 -e bash -c "echo '[boot]`nsystemd=true' | sudo tee /etc/wsl.conf"

# AlmaLinux neustarten
Write-Host "WSL herunterfahren"
wsl --shutdown
Write-Host "Prüfung ob alle Services heruntergefahren"
wsl -l -v
# Schritt 6: Kommunikation zwischen Podman und Docker Compose aktivieren
Write-Host "Kommunikation zwischen Podman und Docker Compose aktivieren..."
# Podman Socket starten und aktivieren
wsl -d AlmaLinuxOS-9 -e bash -c "systemctl start podman.socket"
wsl -d AlmaLinuxOS-9 -e bash -c "systemctl enable podman.socket"

# Testen des Podman Sockets
$response = wsl -d AlmaLinuxOS-9 -e curl -H "Content-Type: application/json" --unix-socket /var/run/docker.sock http://localhost/_ping
Write-Host "Podman Socket Test: $response"

Write-Host "Skript abgeschlossen."