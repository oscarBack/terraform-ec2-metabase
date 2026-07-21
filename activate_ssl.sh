#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="/var/log/activate_ssl.log"
# shellcheck disable=SC2269
metabase_domain="${metabase_domain}"
# shellcheck disable=SC2269
email="${email}"

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
: "$${email:?email must be set}"

execute sudo cp /etc/nginx/sites-available/default "/etc/nginx/sites-available/$metabase_domain"
execute sudo sed -i "s/server_name .*/server_name $metabase_domain;/" "/etc/nginx/sites-available/$metabase_domain"
execute sudo sed -i "/location \/ {/!b;n;c\                # First attempt to serve request as file, then\n                # as directory, then fall back to displaying a 404.\n                try_files \$uri \$uri/ =404;\n        }\n        return 301 https://$metabase_domain;" "/etc/nginx/sites-available/$metabase_domain"
execute sudo nginx -t
execute sudo systemctl reload nginx
execute sudo certbot --nginx -d "$metabase_domain" --email "$email" --agree-tos --non-interactive

log "SSL activation script completed successfully"