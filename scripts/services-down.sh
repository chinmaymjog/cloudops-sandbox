#!/usr/bin/env bash
set -Eeuo pipefail

# DevOps Lab - Services Shutdown Script
# Brings down all services.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
SERVICES_DIR="$BASE_DIR/services"

log() { printf '🛑 %s\n' "$*"; }

log "Stopping all services..."
for service_compose in "$SERVICES_DIR"/*/docker-compose.yml; do
    service_name=$(basename "$(dirname "$service_compose")")
    log "Bringing down $service_name..."
    docker compose -f "$service_compose" down
done

log "All services stopped."
