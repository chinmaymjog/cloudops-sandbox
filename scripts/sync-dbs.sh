#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
ROOT_ENV="$BASE_DIR/.env"

log() { printf '🚀 %s\n' "$*"; }
warn() { printf '⚠️ %s\n' "$*" >&2; }
error() { printf '❌ Error: %s\n' "$*" >&2; exit 1; }

if [[ ! -f "$ROOT_ENV" ]]; then
    error "Root .env not found at $ROOT_ENV"
fi

set -a
# shellcheck disable=SC1090
source "$ROOT_ENV"
set +a

require_var() {
    local name=$1
    if [[ -z "${!name:-}" ]]; then
        error "Required variable '$name' is not set in .env"
    fi
}

require_container() {
    local name=$1
    if ! docker ps --format '{{.Names}}' | grep -qx "$name"; then
        error "Required container '$name' is not running"
    fi
}

require_var POSTGRES_PASSWORD
require_var KEYCLOAK_DB_PASSWORD
require_var N8N_DB_PASSWORD
require_var GRAFANA_DB_PASSWORD
require_var MYSQL_ROOT_PASSWORD

require_container postgresql
log "Syncing PostgreSQL databases with current root .env credentials..."
docker exec \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_USER="${POSTGRES_USER:-postgres}" \
    -e KEYCLOAK_DB_PASSWORD="$KEYCLOAK_DB_PASSWORD" \
    -e N8N_DB_PASSWORD="$N8N_DB_PASSWORD" \
    -e GRAFANA_DB_PASSWORD="$GRAFANA_DB_PASSWORD" \
    -i postgresql \
    bash /docker-entrypoint-initdb.d/init-databases.sh

if docker ps --format '{{.Names}}' | grep -qx mysql; then
    if docker exec mysql test -f /docker-entrypoint-initdb.d/init-databases.sh; then
        log "Syncing MySQL databases with current root .env credentials..."
        docker exec \
            -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
            -i mysql \
            bash /docker-entrypoint-initdb.d/init-databases.sh
    else
        warn "MySQL init script is not present in the running mysql container; skipping MySQL sync"
    fi
else
    warn "MySQL container is not running; skipping MySQL sync"
fi

log "Database sync complete!"
