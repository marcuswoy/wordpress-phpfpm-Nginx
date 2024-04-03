FROM docker.io/php:8.3.4-fpm
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd mysqli pdo_mysql opcache imagick exif zip mcrypt pspell redis sockets ssh2 bcmath