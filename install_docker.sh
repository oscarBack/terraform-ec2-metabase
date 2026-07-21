#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="/var/log/install_docker.log"

# shellcheck disable=SC2154
db_connection_uri="jdbc:postgresql://${db_username}:${db_password}@${db_host}:5432/metabase"

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

fail() {
    log "ERROR: $1"
    exit 1
}

trap 'log "ERROR: unexpected failure at line $${LINENO}"' ERR

exec &> >(tee -a "$LOG_FILE")

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

log "Waiting for system updates to complete..."
wait_for_apt || exit 1

log "Starting Docker installation and Metabase setup"

log "Installing Docker prerequisites"
retry_command sudo apt-get update || fail "apt-get update failed"
wait_for_apt || fail "apt lock wait failed"
retry_command sudo apt-get install -y ca-certificates curl gnupg || fail "Docker prerequisites installation failed"

log "Setting up Docker repository"
retry_command sudo install -m 0755 -d /etc/apt/keyrings || fail "Failed to create apt keyring directory"
retry_command curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || fail "Failed to download Docker GPG key"
retry_command sudo chmod a+r /etc/apt/keyrings/docker.gpg || fail "Failed to secure Docker GPG key"

log "Adding Docker repository to sources"
docker_architecture="$(dpkg --print-architecture)"
# shellcheck disable=SC1091
docker_codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
docker_repository="deb [arch=$docker_architecture signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $docker_codename stable"
retry_command sudo tee /etc/apt/sources.list.d/docker.list <<< "$docker_repository" > /dev/null || fail "Failed to add Docker repository"

log "Installing Docker Engine"
retry_command sudo apt-get update || fail "apt-get update failed"
wait_for_apt || fail "apt lock wait failed"
retry_command sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || fail "Docker Engine installation failed"

log "Pulling Metabase image"
retry_command sudo docker pull metabase/metabase:v0.52.6.x || fail "Failed to pull Metabase image"

log "Starting Metabase container"
log "Database host: ${db_host}"

retry_command sudo docker run -d --restart always -p 3000:3000 \
  -e "MB_DB_TYPE=postgres" \
    -e "MB_DB_CONNECTION_URI=$db_connection_uri" \
  --name metabase metabase/metabase:v0.52.6.x || fail "Failed to start Metabase container"

log "Docker installation and Metabase setup completed successfully"
