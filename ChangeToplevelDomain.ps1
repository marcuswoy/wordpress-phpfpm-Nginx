# Skript Start
Write-Host "Skript gestartet..."

# Schritt 1: DOMAIN_ALT und DOMAIN_NEU aus der .env Datei lesen
Write-Host "Schritt 1: Lesen von DOMAIN_ALT und DOMAIN_NEU aus der .env-Datei..."
$envPath = "./.env"
$envContent = Get-Content -Path $envPath
$domainAlt = ($envContent | Where-Object { $_ -like "DOMAIN_ALT=*" }) -replace 'DOMAIN_ALT=', ''
$domainNeu = ($envContent | Where-Object { $_ -like "DOMAIN_NEU=*" }) -replace 'DOMAIN_NEU=', ''

if (-not $domainAlt -or -not $domainNeu) {
    Write-Host "DOMAIN_ALT oder DOMAIN_NEU nicht in der .env gefunden. Skript wird beendet."
    exit
}
Write-Host "Alte Domain: $domainAlt"
Write-Host "Neue Domain: $domainNeu"

# Schritt 2: Überprüfen und Erstellen von Zertifikaten für die neue Domain
Write-Host "Schritt 2: Prüfen, ob mkcert vorhanden ist und Zertifikate für $domainNeu erstellen..."
$mkcertPath = Join-Path -Path $PSScriptRoot -ChildPath "system/traefik/certs/mkcert.exe"
if (-not (Test-Path $mkcertPath)) {
    Write-Host "mkcert.exe nicht gefunden unter $mkcertPath. Bitte überprüfen Sie den Pfad."
    exit
}
Set-Location -Path (Split-Path -Path $mkcertPath)
$certFiles = "$domainNeu.cert", "$domainNeu.key"
$certExists = $true
foreach ($file in $certFiles) {
    if (-not (Test-Path $file)) {
        $certExists = $false
    }
}
if ($certExists) {
    Write-Host "Zertifikate für $domainNeu existieren bereits, Überspringen der Erstellung."
} else {
    Write-Host "Erstellen von Zertifikaten für $domainNeu..."
    & $mkcertPath -cert-file "$domainNeu.cert" -key-file "$domainNeu.key" "*.$domainNeu" "$domainNeu" "www.$domainNeu"
    Write-Host "Zertifikate für $domainNeu installieren..."
    & $mkcertPath -install
}
Set-Location -Path $PSScriptRoot


# Schritt 3: Anpassen der system/traefik/.env für die neue Domain
Write-Host "Schritt 3: Anpassen von DOMAINNAME in der system/traefik/.env-Datei..."
$traefikEnvPath = "./system/.env"
$traefikEnvContent = Get-Content -Path $traefikEnvPath
if ($traefikEnvContent -like "*DOMAINNAME=$domainAlt*") {
    $traefikEnvContent = $traefikEnvContent -replace "DOMAINNAME=$domainAlt", "DOMAINNAME=$domainNeu"
    $traefikEnvContent | Set-Content -Path $traefikEnvPath
    Write-Host "DOMAINNAME in system/traefik/.env ($traefikEnvPath) auf $domainNeu geändert."
} else {
    Write-Host "DOMAINNAME in system/traefik/.env ($traefikEnvPath) ist bereits auf $domainNeu gesetzt."
}

# Schritt 4: Anpassen der certificates.toml für die neue Domain
Write-Host "Schritt 4: Anpassen der certificates.toml-Datei für $domainNeu..."
$certificatesPath = "./system/traefik/rules/certificates.toml"
$certContent = Get-Content -Path $certificatesPath
$certContent = $certContent -replace "/etc/certs/$domainAlt.cert", "/etc/certs/$domainNeu.cert"
$certContent = $certContent -replace "/etc/certs/$domainAlt.key", "/etc/certs/$domainNeu.key"
$certContent | Set-Content -Path $certificatesPath
Write-Host "Zertifikatspfade in certificates.toml ($certificatesPath) auf $domainNeu geändert."

# Schritt 5: Bearbeiten der Nginx-Konfigurationsdatei für die neue Domain
Write-Host "Schritt 5: Bearbeiten der Nginx-Konfigurationsdatei für $domainNeu..."
$nginxConfigPath = "./websites/$domainAlt/prod/system/nginx/sites/$domainAlt.conf"
if (Test-Path $nginxConfigPath) {
    $nginxContent = Get-Content -Path $nginxConfigPath
    $nginxContent = $nginxContent -replace $domainAlt, $domainNeu
    $nginxContent | Set-Content -Path $nginxConfigPath
    Write-Host "Nginx-Konfigurationsdatei ($nginxConfigPath) für $domainNeu aktualisiert."
}

# Schritt 6: Umbenennen der Nginx-Konfigurationsdatei auf die neue Domain
Write-Host "Schritt 6: Umbenennen der Nginx-Konfigurationsdatei auf $domainNeu..."
$nginxConfigPath = "./websites/$domainAlt/prod/system/nginx/sites/$domainAlt.conf"
$newNginxConfigName = "$domainNeu.conf"

if (Test-Path $nginxConfigPath) {
    Rename-Item -Path $nginxConfigPath -NewName $newNginxConfigName
    Write-Host "Nginx-Konfigurationsdatei auf $newNginxConfigName geändert."
} else {
    Write-Host "Die zu ändernde Nginx-Konfigurationsdatei $nginxConfigPath wurde nicht gefunden."
}

# Schritt 7: Anpassen von DOMAINNAME in der .env-Datei des Website-Verzeichnisses
Write-Host "Schritt 7: Anpassen von DOMAINNAME in der .env-Datei des Website-Verzeichnisses..."
$websiteEnvPath = "./websites/$domainAlt/.env"

if (Test-Path $websiteEnvPath) {
    $websiteEnvContent = Get-Content -Path $websiteEnvPath
    if ($websiteEnvContent -like "*DOMAINNAME=$domainAlt*") {
        $websiteEnvContent = $websiteEnvContent -replace "DOMAINNAME=$domainAlt", "DOMAINNAME=$domainNeu"
        $websiteEnvContent | Set-Content -Path $websiteEnvPath
        Write-Host "DOMAINNAME in $websiteEnvPath auf $domainNeu geändert."
    } else {
        Write-Host "DOMAINNAME in $websiteEnvPath ist bereits auf $domainNeu gesetzt. Keine Änderung notwendig."
    }
} else {
    Write-Host "Die .env-Datei im Verzeichnis $websiteEnvPath wurde nicht gefunden."
}

# Schritt 8: Umbenennen des Website-Verzeichnisses auf die neue Domain
Write-Host "Schritt 8: Umbenennen des Website-Verzeichnisses auf $domainNeu..."
$websitePath = "./websites/$domainAlt"
$newWebsitePath = "./websites/$domainNeu"
$newWebsiteName = Split-Path -Leaf $newWebsitePath

if (Test-Path $websitePath) {
    if (-not (Test-Path $newWebsitePath)) {
        Rename-Item -Path $websitePath -NewName $newWebsiteName
        Write-Host "Website-Verzeichnis von $websitePath auf $newWebsitePath geändert."
    } else {
        Write-Host "Das Zielverzeichnis $newWebsitePath existiert bereits. Umbenennung wird übersprungen."
    }
} else {
    Write-Host "Das zu ändernde Website-Verzeichnis $websitePath wurde nicht gefunden."
}

Write-Host "Skript abgeschlossen."