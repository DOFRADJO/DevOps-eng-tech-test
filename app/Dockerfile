FROM php:8.1-fpm

#install Nginx
RUN apt-get update && apt-get install -y Nginx

#Copy configurations files
COPY nginx.conf /etc/nginx/sites-available/default
COPY index.php /var/www/html/index.php

#expose the service at default port
EXPOSE 8080
