#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="/var/log/install_psql.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

execute() {
    if "$@"; then
        log "SUCCESS: ${1:-command}"
    else
        log "FAILURE: ${1:-command}"
        exit 1
    fi
}

wait_for_apt() {
    local max_attempts=60
    local attempt=1

    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        if (( attempt > max_attempts )); then
            log "ERROR: Timeout waiting for apt locks"
            return 1
        fi
        log "Waiting for apt locks to be released... attempt $attempt"
        sleep 10
        attempt=$((attempt + 1))
    done
    return 0
}

retry_command() {
    local max_attempts=3
    local attempt=1

    while (( attempt <= max_attempts )); do
        if "$@"; then
            return 0
        fi

        if (( attempt == max_attempts )); then
            log "ERROR: Command failed after $max_attempts attempts"
            return 1
        fi

        log "Command failed. Retrying in 30 seconds... (attempt $attempt/$max_attempts)"
        sleep 30
        attempt=$((attempt + 1))
    done
}

trap 'log "ERROR: unexpected failure at line ${LINENO}"' ERR

exec &> >(tee -a "$LOG_FILE")

log "Starting PostgreSQL client installation"
log "Waiting for system updates to complete..."
wait_for_apt || exit 1

log "Adding PostgreSQL repository"
postgresql_repository="deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main"
execute sudo tee /etc/apt/sources.list.d/pgdg.list <<< "$postgresql_repository" > /dev/null
execute bash -c 'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -'

log "Installing PostgreSQL client"
retry_command sudo apt-get update || exit 1
retry_command sudo apt-get install -y postgresql-client-16 || exit 1

log "Verifying PostgreSQL client installation"
if psql --version; then
    log "PostgreSQL client installation completed successfully"
else
    log "PostgreSQL client installation failed"
    exit 1
fi

