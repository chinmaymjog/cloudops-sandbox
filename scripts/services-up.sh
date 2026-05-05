#!/usr/bin/env bash
set -Eeuo pipefail

# DevOps Lab - Services Startup Script
# Brings up all services in the correct order.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
SERVICES_DIR="$BASE_DIR/services"

log() { printf '🚀 %s\n' "$*"; }

# 1. Start Networks & Infrastructure
log "Starting network and core infrastructure..."
./scripts/setup.sh

# 2. Start Databases (First, so others can connect)
log "Starting Databases (PostgreSQL, MySQL)..."
docker compose -f "$SERVICES_DIR/pgsql/docker-compose.yml" up -d
docker compose -f "$SERVICES_DIR/mysql/docker-compose.yml" up -d

# Wait a few seconds for DBs to be ready
log "Waiting for databases to initialize..."
sleep 5

# 3. Start Proxy (Traefik)
log "Starting Traefik Proxy..."
docker compose -f "$SERVICES_DIR/traefik/docker-compose.yml" up -d

# 4. Start all other services
log "Starting all other services..."
for service_compose in "$SERVICES_DIR"/*/docker-compose.yml; do
    service_name=$(basename "$(dirname "$service_compose")")
    
    # Skip already started services
    if [[ "$service_name" == "pgsql" || "$service_name" == "mysql" || "$service_name" == "traefik" ]]; then
        continue
    fi
    
    log "Bringing up $service_name..."
    docker compose -f "$service_compose" up -d
done

log "All services are up! Check status with 'docker ps'"
