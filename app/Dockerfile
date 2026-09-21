FROM php:8.2-apache

# Instalar extensión para conectar PHP con MySQL
RUN docker-php-ext-install mysqli

COPY . /var/www/html/

WORKDIR /var/www/html