#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
ROOT_ENV="$BASE_DIR/.env"

log() { printf '🚀 %s\n' "$*"; }
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
require_var N8N_DB_PASSWORD
require_var GRAFANA_DB_PASSWORD

require_container postgresql
log "Syncing PostgreSQL databases with current root .env credentials..."
docker exec \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_USER="${POSTGRES_USER:-postgres}" \
    -e N8N_DB_PASSWORD="$N8N_DB_PASSWORD" \
    -e GRAFANA_DB_PASSWORD="$GRAFANA_DB_PASSWORD" \
    -i postgresql \
    bash /docker-entrypoint-initdb.d/init-databases.sh

log "Database sync complete!"
