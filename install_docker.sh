#!/bin/bash

LOG_FILE="/var/log/install_docker.log"

db_connection_uri="jdbc:postgresql://${db_username}:${db_password}@${db_host}5432/metabase"


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

# Function to wait for apt locks
wait_for_apt() {
    local max_attempts=60  # Maximum number of attempts (10 minutes)
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
    local cmd=$(printf "%s " "$@")
    local max_attempts=3
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

# Print database connection string for debugging
log "Database connection URI: $db_connection_uri"

# Wait for initial unattended-upgrades to finish
log "Waiting for system updates to complete..."
wait_for_apt || exit 1

log "Starting Docker installation and Metabase setup"

# Install Docker
log "Installing Docker prerequisites"
retry_command sudo apt-get update
wait_for_apt
retry_command sudo apt-get install -y ca-certificates curl gnupg

log "Setting up Docker repository"
retry_command sudo install -m 0755 -d /etc/apt/keyrings
retry_command curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
retry_command sudo chmod a+r /etc/apt/keyrings/docker.gpg

log "Adding Docker repository to sources"
retry_command echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log "Installing Docker Engine"
retry_command sudo apt-get update
wait_for_apt
retry_command sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Pull Metabase image
log "Pulling Metabase image"
retry_command sudo docker pull metabase/metabase:v0.52.6.x

# Run Metabase container
log "Starting Metabase container"

log "Database username: ${db_username}" 
log "Database password: ${db_password}"
log "Database host: ${db_host}"
log "Database connection URI: $db_connection_uri"

retry_command sudo docker run -d --restart always -p 3000:3000 \
-e "MB_DB_TYPE=postgres" \
-e "MB_DB_CONNECTION_URI=jdbc:postgresql://${db_username}:${db_password}@${db_host}/metabase" \
--name metabase metabase/metabase:v0.52.6.x

log "Docker installation and Metabase setup completed successfully"
