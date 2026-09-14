#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - stacks Startup Script
# Brings up all stacks in the correct order.
#
# Core stacks (traefik, cloudflared, pgsql, grafana, prometheus, n8n) always
# start. Optional stacks are gated behind Docker Compose profiles and only
# start when named in PROFILE (comma-separated, or "all" for every group):
#   PROFILE=identity make up    # + keycloak
#   PROFILE=db-admin make up    # + mysql, adminer, phpmyadmin
#   PROFILE=management make up  # + portainer, wud
#   PROFILE=all make up         # everything

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
STACKS_DIR="$BASE_DIR/stacks"
ROOT_ENV="$BASE_DIR/.env"
PROFILE="${PROFILE:-}"

log() { printf '🚀 %s\n' "$*"; }

if [[ -f "$ROOT_ENV" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ROOT_ENV"
    set +a
fi

PROFILE_ARGS=()
if [[ "$PROFILE" == "all" ]]; then
    PROFILE_ARGS=(--profile identity --profile db-admin --profile management)
elif [[ -n "$PROFILE" ]]; then
    IFS=',' read -ra profile_groups <<< "$PROFILE"
    for group in "${profile_groups[@]}"; do
        PROFILE_ARGS+=(--profile "$group")
    done
fi
if [[ ${#PROFILE_ARGS[@]} -gt 0 ]]; then
    log "Optional stack groups requested: ${PROFILE_ARGS[*]}"
fi

# 1. Start Networks & Infrastructure
log "Starting network and core infrastructure..."
./scripts/setup.sh

# 2. Start Databases (First, so others can connect)
# pgsql is core and always starts; mysql is gated behind the db-admin
# profile and is a no-op here unless PROFILE includes it.
log "Starting Databases (PostgreSQL, MySQL)..."
docker compose -f "$STACKS_DIR/pgsql/docker-compose.yml" up -d
docker compose "${PROFILE_ARGS[@]}" -f "$STACKS_DIR/mysql/docker-compose.yml" up -d

# Wait a few seconds for DBs to be ready
log "Waiting for databases to initialize..."
sleep 5

# 3. Start Proxy (Traefik)
log "Starting Traefik Proxy..."
docker compose -f "$STACKS_DIR/traefik/docker-compose.yml" up -d

# 4. Start all other stacks (auto-discovered). Core stacks have no
# `profiles:` entry so they always start; optional stacks only start when
# their profile is in PROFILE_ARGS.
log "Starting all other stacks..."
for stack_compose in "$STACKS_DIR"/*/docker-compose.yml; do
    stack_name=$(basename "$(dirname "$stack_compose")")

    # Skip already started stacks
    if [[ "$stack_name" == "pgsql" || "$stack_name" == "mysql" || "$stack_name" == "traefik" ]]; then
        continue
    fi

    log "Bringing up $stack_name..."
    docker compose "${PROFILE_ARGS[@]}" -f "$stack_compose" up -d
done

log "All stacks are up! Check status with 'docker ps'"
if [[ ${#PROFILE_ARGS[@]} -eq 0 ]]; then
    log "Core stacks only. Add optional groups with e.g. 'make up PROFILE=identity' (see README)."
fi
