#!/bin/bash

LOG_FILE="/var/log/activate_ssl.log"
metabase_domain="${metabase_domain}"
email="${email}"

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

# Rename the configuration file for the metabase_domain
execute sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/$metabase_domain

# Open the configuration file for the metabase_domain and update server_name
execute sudo sed -i "s/server_name .*/server_name $metabase_domain;/" /etc/nginx/sites-available/$metabase_domain

# Update the location block in the configuration file
execute sudo sed -i '/location \/ {/!b;n;c\                # First attempt to serve request as file, then\n                # as directory, then fall back to displaying a 404.\n                try_files $uri $uri/ =404;\n        }\n        return 301 https://$metabase_domain;' /etc/nginx/sites-available/$metabase_domain

# Test the Nginx configuration
execute sudo nginx -t

# Reload Nginx to apply changes
execute sudo systemctl reload nginx

# Obtain SSL certificate using Certbot
execute sudo certbot --nginx -d $metabase_domain --email $email --agree-tos --non-interactive

log "SSL activation script completed successfully"