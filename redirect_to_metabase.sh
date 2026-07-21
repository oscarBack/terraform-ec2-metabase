#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="/var/log/redirect_to_metabase.log"
# shellcheck disable=SC2269
metabase_domain="${metabase_domain}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

execute() {
    if "$@"; then
        log "SUCCESS: $${1:-command}"
    else
        log "FAILURE: $${1:-command}"
        exit 1
    fi
}

trap 'log "ERROR: unexpected failure at line $${LINENO}"' ERR

exec &> >(tee -a "$LOG_FILE")

: "$${metabase_domain:?metabase_domain must be set}"

log "Starting Redirect to Metabase"

NGINX_CONF="/etc/nginx/sites-available/default"

cat <<EOF | sudo tee "$NGINX_CONF"
server {
    listen 80;
    listen [::]:80;
    server_name $metabase_domain;
    return 301 https://$metabase_domain\$request_uri;
}

server {
    server_name $metabase_domain;

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$metabase_domain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$metabase_domain/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    location / {
      proxy_pass http://127.0.0.1:3000;
    }
}
EOF

log "Created Nginx configuration file"
execute sudo nginx -t
execute sudo systemctl reload nginx

log "Completed Metabase redirect configuration"
