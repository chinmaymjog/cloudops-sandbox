#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - stacks Startup Script
# Brings up all stacks in the correct order.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
STACKS_DIR="$BASE_DIR/stacks"

log() { printf '🚀 %s\n' "$*"; }

# 1. Start Networks & Infrastructure
log "Starting network and core infrastructure..."
./scripts/setup.sh

# 2. Start Databases (First, so others can connect)
log "Starting Databases (PostgreSQL, MySQL)..."
docker compose -f "$STACKS_DIR/pgsql/docker-compose.yml" up -d
docker compose -f "$STACKS_DIR/mysql/docker-compose.yml" up -d

# Wait a few seconds for DBs to be ready
log "Waiting for databases to initialize..."
sleep 5

# 3. Start Proxy (Traefik)
log "Starting Traefik Proxy..."
docker compose -f "$STACKS_DIR/traefik/docker-compose.yml" up -d

# 4. Start all other stacks
log "Starting all other stacks..."
for stack_compose in "$STACKS_DIR"/*/docker-compose.yml; do
    stack_name=$(basename "$(dirname "$stack_compose")")
    
    # Skip already started stacks
    if [[ "$stack_name" == "pgsql" || "$stack_name" == "mysql" || "$stack_name" == "traefik" ]]; then
        continue
    fi
    
    log "Bringing up $stack_name..."
    docker compose -f "$stack_compose" up -d
done

log "All stacks are up! Check status with 'docker ps'"
