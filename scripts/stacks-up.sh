#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - stacks Startup Script
# Brings up all stacks in the correct order.
#
# Every service carries a `profiles:` entry, so Docker Compose starts nothing
# unless a matching --profile is passed. The base set (core + monitoring) is
# always passed. Optional groups start only when named in PROFILE
# (comma-separated, or "all" for every group):
#   PROFILE=management make up  # + keycloak, portainer, wud
#   PROFILE=database make up    # + mysql
#   PROFILE=all make up         # everything

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
STACKS_DIR="$BASE_DIR/stacks"
ROOT_ENV="$BASE_DIR/.env"
PROFILE="${PROFILE:-}"
KNOWN_GROUPS="core monitoring management database"

log() { printf '🚀 %s\n' "$*"; }

if [[ -f "$ROOT_ENV" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ROOT_ENV"
    set +a
fi

PROFILE_ARGS=(--profile core --profile monitoring)
if [[ "$PROFILE" == "all" ]]; then
    PROFILE_ARGS+=(--profile management --profile database)
elif [[ -n "$PROFILE" ]]; then
    IFS=',' read -ra profile_groups <<< "$PROFILE"
    for group in "${profile_groups[@]}"; do
        if [[ " $KNOWN_GROUPS " != *" $group "* ]]; then
            printf '❌ Unknown PROFILE group "%s". Valid groups: %s (or "all")\n' "$group" "$KNOWN_GROUPS" >&2
            exit 1
        fi
        PROFILE_ARGS+=(--profile "$group")
    done
fi
log "Active profiles: ${PROFILE_ARGS[*]}"

# Bring up one stack. Compose exits non-zero with "no service selected" when
# every service in the file is filtered out by the active profiles, so check
# first and skip those stacks rather than letting `set -e` abort the run.
stack_up() {
    local compose_file="$1" name services
    name=$(basename "$(dirname "$compose_file")")
    services=$(docker compose "${PROFILE_ARGS[@]}" -f "$compose_file" config --services)
    if [[ -z "$services" ]]; then
        log "Skipping $name (not in the active profiles)"
        return 0
    fi
    log "Bringing up $name..."
    docker compose "${PROFILE_ARGS[@]}" -f "$compose_file" up -d
}

# 1. Start Networks & Infrastructure
log "Starting network and core infrastructure..."
./scripts/setup.sh

# 2. Start Databases (First, so others can connect)
# pgsql is core and always starts; mysql is in the `database` profile and is
# skipped here unless PROFILE includes it.
log "Starting Databases (PostgreSQL, MySQL)..."
stack_up "$STACKS_DIR/pgsql/docker-compose.yml"
stack_up "$STACKS_DIR/mysql/docker-compose.yml"

# Wait a few seconds for DBs to be ready
log "Waiting for databases to initialize..."
sleep 5

# 3. Start Proxy (Traefik)
log "Starting Traefik Proxy..."
stack_up "$STACKS_DIR/traefik/docker-compose.yml"

# 4. Start all other stacks (auto-discovered). Each is started only if it has
# at least one service in the active profiles.
log "Starting all other stacks..."
for stack_compose in "$STACKS_DIR"/*/docker-compose.yml; do
    stack_name=$(basename "$(dirname "$stack_compose")")

    # Skip already started stacks
    if [[ "$stack_name" == "pgsql" || "$stack_name" == "mysql" || "$stack_name" == "traefik" ]]; then
        continue
    fi

    stack_up "$stack_compose"
done

log "All stacks are up! Check status with 'docker ps'"
if [[ -z "$PROFILE" ]]; then
    log "Base stacks only. Add optional groups with e.g. 'make up PROFILE=management' (see README)."
fi
