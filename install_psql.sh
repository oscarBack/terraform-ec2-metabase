#!/bin/bash

LOG_FILE="/var/log/install_psql.log"

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

# Function to wait for apt locks
wait_for_apt() {
    local max_attempts=60
    local attempt=1

    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        if [ $attempt -gt $max_attempts ]; then
            log "ERROR: Timeout waiting for apt locks"
            return 1
        fi
        log "Waiting for apt locks to be released... attempt $attempt"
        sleep 10
        attempt=$((attempt + 1))
    done
    return 0
}

# Function to retry commands
retry_command() {
    local -r cmd="${*}"
    local -r max_attempts=3
    local attempt=1

    until $cmd; do
        if ((attempt == max_attempts)); then
            log "ERROR: Command '$cmd' failed after $max_attempts attempts"
            return 1
        fi
        log "Command '$cmd' failed. Retrying in 30 seconds... (attempt $attempt/$max_attempts)"
        sleep 30
        ((attempt++))
    done
    return 0
}

# Redirect output and errors to log file
exec &> >(tee -a "$LOG_FILE")

log "Starting PostgreSQL client installation"

# Wait for initial unattended-upgrades to finish
log "Waiting for system updates to complete..."
wait_for_apt || exit 1

# Add PostgreSQL repository
log "Adding PostgreSQL repository"
execute sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
execute wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package list and install PostgreSQL client
log "Installing PostgreSQL client"
execute sudo apt-get update
execute sudo apt-get install -y postgresql-client-16

# Verify installation
log "Verifying PostgreSQL client installation"
if psql --version; then
    log "PostgreSQL client installation completed successfully"
else
    log "PostgreSQL client installation failed"
    exit 1
fi

