#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - stacks Shutdown Script
# Brings down all stacks.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
STACKS_DIR="$BASE_DIR/stacks"
ROOT_ENV="$BASE_DIR/.env"

log() { printf '🛑 %s\n' "$*"; }

if [[ -f "$ROOT_ENV" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ROOT_ENV"
    set +a
fi

log "Stopping all stacks..."
for stack_compose in "$STACKS_DIR"/*/docker-compose.yml; do
    stack_name=$(basename "$(dirname "$stack_compose")")
    log "Bringing down $stack_name..."
    docker compose -f "$stack_compose" down
done

log "All stacks stopped."
