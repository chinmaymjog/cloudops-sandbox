#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - stacks Shutdown Script
# Brings down all stacks.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
STACKS_DIR="$BASE_DIR/stacks"

log() { printf '🛑 %s\n' "$*"; }

log "Stopping all stacks..."
for stack_compose in "$STACKS_DIR"/*/docker-compose.yml; do
    stack_name=$(basename "$(dirname "$stack_compose")")
    log "Bringing down $stack_name..."
    docker compose -f "$stack_compose" down
done

log "All stacks stopped."
