FROM php:7.3-apache

# Require UID and GID of host user, so that we can map the user inside
# the container to the user in the host to prevent permissions issues
ARG UID
ARG GID

# Enable mod_rewrite and mod_header
# This command doesn't work after the development command
RUN a2enmod rewrite headers

# Development packages & dependencies
RUN apt-get update && apt-get install -y \
        curl \
        zip \
        unzip \
        git \
        supervisor \
        nano \
    && docker-php-ext-install bcmath && docker-php-ext-enable bcmath \
    && docker-php-ext-install pdo_mysql && docker-php-ext-enable pdo_mysql \
    && docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Copy composer form latest composer image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy apache configuration file
COPY etc/docker/apache2/default.conf /etc/apache2/sites-available/000-default.conf

# Create user dartmoon mapped to the host user using same UID and GID
RUN useradd -G www-data,root -u $UID -g $GID -s /bin/bash -m dartmoon

# Execute everything as new user
USER dartmoon
