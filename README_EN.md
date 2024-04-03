# WordPress with PHP-FPM, Nginx, and Valid Certificate over WSL2 Alma-Linux

This guide explains how to install WordPress with useful add-ons in an isolated WSL distribution on your computer. It shows how to set up your own domain with a valid certificate to avoid SSL errors in the browser.

**After completing this guide, the following areas will be accessible:**
- `https://example.com`
- `https://traefik.example.com`
- `https://adminer.example.com`
- `https://logger.example.com`

## Prerequisites
- Administrator rights on a Windows 11 system with current updates
- Basic knowledge of Linux, Podman, and Docker Compose
- Download [mkcert](https://github.com/FiloSottile/mkcert/releases), rename it to `mkcert.exe`, and place it in `./system/traefik/certs`.
- For access protection, create a `.htpasswd` file in `./system/traefik/security/`.

## Automated Changes
Two PowerShell scripts automate the process described below. Before running the scripts, please adjust the `DOMAIN_NEU` variable in the `.env` file in the root directory.

### InstallDependencies.ps1
- Run the script: `.\\InstallDependencies.ps1` in PowerShell.
- The terminal must be in the project's root directory.

### ChangeToplevelDomain.ps1
- The script changes `example.com` to the desired domain.
- The new domain is entered in the `.env` file as `DOMAIN_NEU`.
- If the domain name changes, `DOMAIN_NEU` can be moved to `DOMAIN_ALT`.
- The script searches for matches in `DOMAIN_ALT` and changes them to `DOMAIN_NEU`.

## Manual Changes
- Replace all references to `example.com` with the desired domain.

### 1. Create Certificates
- Navigate to the `./system/traefik/certs` folder.
- Execute:
    ```
    .\\mkcert.exe -cert-file example.com.cert -key-file example.com.key *.example.com example.com www.example.com
    ```
- Run `mkcert.exe -install` and confirm adding the certificate to the trusted root certificates to avoid later SSL warnings in the browser.
- Go to `/system/traefik/rules` and adjust the name of the certificate in `certificates.toml`.

### 2. Edit Hosts File
- Add the following lines to the `hosts` file:
    ```
    127.0.0.1 example.com
    127.0.0.1 traefik.example.com
    127.0.0.1 adminer.example.com
    127.0.0.1 logger.example.com
    ```

### 3. Install AlmaLinux
- Download and install [AlmaLinux 9](https://apps.microsoft.com/detail/9p5rwlm70sn9) from the Windows Store.
- After installation, log in with `wsl -d AlmaLinuxOS-9` and run `dnf update`.

### 4. Install Podman and Docker Compose in AlmaLinux
- Install Podman: `dnf install -y podman podman-docker`
- Install Docker Compose:
    ```
    curl -L "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
    ```
- Check the installations with `docker-compose -v` and `podman -v`.

### 5. Activate Systemd
- Edit `/etc/wsl.conf` with `nano` and add:
    ```
    [boot]
    systemd=true
    ```
- Shut down AlmaLinux and restart with `wsl --shutdown`. Then log in with `wsl -d AlmaLinuxOS-9`.
- Confirm the activation of systemd with `systemctl list-units --type=service`.

### 6. Enable Communication between Podman and Docker Compose
1. Start the Podman socket: `systemctl start podman.socket`.
2. Enable automatic start on reboot: `systemctl enable podman.socket`.
3. Test the Podman socket (should return "OK"): 
    ```
    curl -H "Content-Type: application/json" --unix-socket /var/run/docker.sock http://localhost/_ping
    ```

## Project Transfer
- Transfer the project directly into the distribution or integrate it via Visual Studio Code using the "WSL: Reopen in WSL" option.

## Adjust Reverse Proxy
- Go to `/system/.env` and adjust the `DOMAINNAME` variable.

## Website Configuration
- Make adjustments to Nginx, PHP-FPM, the database, and WordPress.

### General Adjustments
1. Change the folder name in `/websites/example.com` to the desired domain.
2. Adjust the file name in `/websites/example.com/prod/system/nginx/sites` to the desired domain.
3. Adjust `DOMAINNAME` and `DB_PASSWORD` in `/websites/example.com/.env`.

### Adjust Nginx
- Open `/websites/example.com/prod/system/nginx/sites/example.com.conf`.
- Replace `example.com` with the desired domain in the following lines:
    - `return 301 https://example.com$request_uri;`
    - `server_name example.com;`
    - `access_log /var/log/nginx/example.com-access.log;`
    - `error_log /var/log/nginx/example.com-error.log;`

## Application Start
- Check for newer versions of PHP before starting the application (e.g., `FROM docker.io/php:*8.3.4*-fpm`).
1. Create the network: `docker network create web`.
2. Go to `./system/` and start the reverse proxy: `docker-compose up -d`.
3. Navigate to `./websites`, download WordPress, and place it in `./websites/example.com/prod/data`.
4. Start the application: `docker-compose up -d`.
5. Open `adminer.example.com` and log in.
6. Create a database with the desired name and character set `utf8mb3_general_ci`.
7. Visit `https://example.com` and follow the installation instructions. Note that mixed content may cause style issues but won't affect functionality.
8. After successful installation, open `/websites/example.com/prod/data/wp-config.php` and add the following code after the comment `Add unique values between this line and the 'Stop editing' line.`:
    ```php
    if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
        $_SERVER['HTTPS'] = 'on';
    }
    ```
