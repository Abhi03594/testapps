FROM php:7.1-apache


# Latest at 202002
ENV SCRM_VERSION v7.11.15

# Install requirements
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get \
        install -y --no-install-recommends \
            libfreetype6-dev \
            libjpeg62-turbo-dev \
            libmcrypt-dev \
            libcurl4-openssl-dev \
            libssl-dev \
            libpng-dev \
            libpq-dev \
            libxml2-dev \
            zlib1g-dev \
            libc-client-dev \
            libkrb5-dev \
            libldap2-dev \
            libicu-dev \
            cron \
            git \
            busybox

# Busybox installation
RUN busybox --install

# Docker image configuration
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) iconv \
		    mcrypt \
				pdo_mysql \
        curl \
        mbstring \
        mysqli \
        zip \
        ftp \
        pdo_pgsql \
        gd \
        fileinfo \
        soap \
        zip \
        imap \
        ldap \
        intl

WORKDIR /var/www/html

USER www-data

# SetUP SuiteCRM
RUN curl https://codeload.github.com/salesagility/SuiteCRM/tar.gz/${SCRM_VERSION} | tar xzv --strip 1

# SetUp config file redirect for proper use with docker volumes
RUN mkdir conf.d \
    && touch conf.d/config.php conf.d/config_override.php \
    && ln -s conf.d/config.php \
    && ln -s conf.d/config_override.php

RUN (crontab -l 2>/dev/null; echo "* * * * *  php -f /var/www/html/cron.php > /dev/null 2>&1 ") | crontab -

USER root

# SetUp php composer
RUN php --ini
RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
RUN php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN composer install --no-plugins --no-scripts
RUN chown -R www-data:www-data . && chmod -R 775 .
COPY php.custom.ini /usr/local/etc/php/conf.d/

# SetUp bootstrap files
RUN mkdir /bootstrap
RUN curl -o /bootstrap/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && chmod +x /bootstrap/wait-for-it
COPY ./bootstrap /bootstrap
RUN chown -R www-data:www-data /bootstrap && chmod -R 775 /bootstrap

# Clean temporary files and packages and final tweaks
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN sed -i 's/Listen 80/Listen 3000/g' /etc/apache2/ports.conf

USER www-data
VOLUME [ "/var/www/html/upload", "/var/www/html/conf.d" ]

EXPOSE 3000

CMD ["/bootstrap/suitecrm-init.sh"]

# End of file
# vim: set ts=2 sw=2 noet:

