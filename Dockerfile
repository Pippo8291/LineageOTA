FROM php:8.2.17-apache
#MAINTAINER Julian Xhokaxhiu <info at julianxhokaxhiu dot com>

# internal variables
ENV HTML_DIR /var/www/html
ENV AXP_DIR /var/www/html/axp
ENV FULL_BUILDS_DIR $AXP_DIR/builds/full

# set the working directory
WORKDIR $AXP_DIR

# enable mod_rewrite
RUN a2enmod rewrite

# install the PHP extensions we need
RUN apt-get update \
        && buildDeps=" \
                zlib1g-dev \
                libzip-dev \
        " \
        && apt-get install -y git libzip4 $buildDeps --no-install-recommends \
        && rm -r /var/lib/apt/lists/* \
        \
        && docker-php-ext-install zip \
        \
        && pecl install apcu \
        && docker-php-ext-enable apcu \
        \
        && docker-php-source delete \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps

# set recommended settings for APCu
# see http://php.net/manual/en/apcu.configuration.php
RUN { \
    echo 'apc.ttl=7200'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# install latest version of composer
ADD https://getcomposer.org/composer.phar /usr/local/bin/composer
RUN chmod 0755 /usr/local/bin/composer

# add all the project files
COPY . $AXP_DIR

# enable indexing for Apache
RUN sed -i "1s;^;Options +Indexes\n\n;" .htaccess

# install dependencies
RUN composer install --optimize-autoloader --no-interaction --no-progress

# fix permissions
RUN chmod -R 0775 /var/www/html \
    && chown -R www-data:www-data /var/www/html

# create volumes
VOLUME $FULL_BUILDS_DIR
