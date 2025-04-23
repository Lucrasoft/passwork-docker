#!/bin/bash

set -ex

if [ ! -f /server/ssl/privkey.pem ] || [ ! -f /server/ssl/fullchain.pem ]; then
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /server/ssl/privkey.pem -out /server/ssl/fullchain.pem \
    -subj "/OU=IT Department/CN=${DOMAIN:-selfsigned.local}"
fi


[ -z "$(ls -A /server/php 2>/dev/null)" ] && cp -n /server/php-default/* /server/php
cp -n /server/php-default/ldap.conf /server/php
cp -n /server/php-default/rsyslog.conf /server/php

# Raise file descriptor limit
ulimit -n 64000


PUSER=${PUSER:-1001}
NUSER=${NUSER:-1001}
APP_UID=1001 

# Schedule task setup
echo "* * * * * cd /server/www && php bin/console tasks:run" > /server/schedule

# Ownership & permissions
chown -R 1001 /server/php /run/php /server/log/php /server/schedule /server/init
chown -R 1001 /server/nginx /server/ssl /server/www/public /server/log /server/logs

# PHP cache warmup (ignore failure but show message)
cd /server/www && gosu "$PUSER" php bin/console cache:warmup || echo "⚠️  PHP cache warmup skipped or failed"

# Start PHP-FPM as 
gosu "$PUSER" php-fpm8.3 --nodaemonize &
PHP_PID=$!

# Start NGINX as root; 
nginx -c /server/nginx/nginx.conf -g "daemon off;" &
NGINX_PID=$!


# Shutdown handler
terminate() {
  echo "Caught SIGTERM/SIGINT... stopping services"
  kill -TERM "$PHP_PID" "$NGINX_PID" 2>/dev/null || true
  wait "$PHP_PID" "$NGINX_PID"
  echo "Shutdown complete"
  exit 0
}
trap terminate SIGTERM SIGINT

# If extra arguments were passed (e.g. /bin/bash), run them in foreground
if [[ "$#" -gt 0 ]]; then
  echo "Running custom command: $@"
  exec "$@"
else
  # Wait for main services
  wait "$PHP_PID" "$NGINX_PID"
fi

