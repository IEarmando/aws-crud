FROM php:8.2-apache

# Instalar extensión para conectar PHP con MySQL
RUN docker-php-ext-install mysqli

COPY index.php /var/www/html/index.php

WORKDIR /var/www/html