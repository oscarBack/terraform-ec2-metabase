#!/bin/bash

LOG_FILE="/var/log/redirect_to_metabase.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to execute a command and log its success or failure
execute() {
    if "$@"; then
        log "SUCCESS: $*"
    else
        log "FAILURE: $*"
        exit 1
    fi
}

# Redirect output and errors to log file
exec &> >(tee -a "$LOG_FILE")

log "Starting Redirect to Metabase"

NGINX_CONF="/etc/nginx/sites-available/default"

# Create Nginx configuration
cat << EOF | sudo tee "$NGINX_CONF"
server {
    listen 80;
    listen [::]:80;
    server_name ${metabase_domain};
    return 301 https://${metabase_domain}$request_uri;
}

server { 
    server_name ${metabase_domain};

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/${metabase_domain}/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/${metabase_domain}/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    location / {
      proxy_pass http://127.0.0.1:3000;
    }

}
EOF

log "Created Nginx configuration file"
# Test Nginx configuration
execute sudo nginx -t

# Reload Nginx to apply changes
execute sudo systemctl reload nginx

log "Completed Metabase redirect configuration"
