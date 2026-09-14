#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - stacks Shutdown Script
# Brings down all stacks.
#
# Docker Compose only tears down profile-gated services when the matching
# --profile flag is passed (same rule as `up`). Down is always maximal, so
# every profile is passed unconditionally here — this is a safe no-op for
# any optional stack that was never started, and guarantees `make down`
# fully cleans up regardless of which PROFILE was used with `make up`.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
STACKS_DIR="$BASE_DIR/stacks"
ROOT_ENV="$BASE_DIR/.env"
ALL_PROFILES=(--profile identity --profile db-admin --profile management)

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
    docker compose "${ALL_PROFILES[@]}" -f "$stack_compose" down
done

log "All stacks stopped."
