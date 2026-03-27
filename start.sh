#!/bin/sh
set -e

# Prepare Laravel dirs on the mounted volume
mkdir -p /var/www/app/storage/logs \
         /var/www/app/storage/framework/cache \
         /var/www/app/storage/framework/sessions \
         /var/www/app/storage/framework/views \
         /var/www/app/bootstrap/cache

chown -R www-data:www-data /var/www/app/storage /var/www/app/bootstrap/cache || true

# Run Laravel optimizations and migrations
php artisan optimize || true
php artisan migrate --force || true

# Start php-fpm in background, nginx in foreground (PID 1)
php-fpm -D
exec nginx -g 'daemon off;'
