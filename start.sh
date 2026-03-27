#!/bin/sh
set -e

# Prepare Laravel dirs
mkdir -p /var/www/app/storage/logs \
         /var/www/app/storage/framework/cache \
         /var/www/app/storage/framework/sessions \
         /var/www/app/storage/framework/views \
         /var/www/app/bootstrap/cache

chown -R www-data:www-data /var/www/app/storage /var/www/app/bootstrap/cache || true

# Wait for MySQL to be ready
echo "Waiting for MySQL at ${DB_HOST}:${DB_PORT:-3306}..."
for i in $(seq 1 60); do
  if php -r "try { new PDO('mysql:host=${DB_HOST};port=${DB_PORT:-3306}', '${DB_USERNAME}', '${DB_PASSWORD}'); echo 'ok'; } catch(Exception \$e) { exit(1); }" 2>/dev/null; then
    echo "MySQL is ready"
    break
  fi
  echo "  attempt $i/60..."
  sleep 2
done

# Run Laravel optimizations
php artisan optimize || true

# Run migrations
echo "Running migrations..."
php artisan migrate --force || true

# Seed database on first run (safe to run repeatedly — checks if already seeded)
echo "Running database seeder..."
php artisan db:seed --force || true

# Create admin account if IN_USER_EMAIL and IN_PASSWORD are set
if [ -n "$IN_USER_EMAIL" ] && [ -n "$IN_PASSWORD" ]; then
  echo "Creating admin account: $IN_USER_EMAIL"
  php artisan ninja:create-account --email="$IN_USER_EMAIL" --password="$IN_PASSWORD" || true
fi

# Design updates
php artisan ninja:design-update || true

echo "Setup complete. Starting services..."

# Start php-fpm in background, nginx in foreground (PID 1)
php-fpm -D
exec nginx -g 'daemon off;'
