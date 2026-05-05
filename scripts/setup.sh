#!/usr/bin/env bash
set -Eeuo pipefail

# DevOps Lab Setup Script
# Combines logic from init.sh and bootstrap-vm.sh for local setup on Mac/Linux.

# --- Configuration ---
NETWORK_NAME="${NETWORK_NAME:-control-plane}"
# Resolve the project root directory (one level up from scripts/)
BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
SERVICES_DIR="$BASE_DIR/services"
ROOT_ENV="$BASE_DIR/.env"

log() { printf '🚀 %s\n' "$*"; }
error() { printf '❌ Error: %s\n' "$*" >&2; exit 1; }

# --- 1. OS Detection ---
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=linux;;
    Darwin*)    PLATFORM=macos;;
    *)          error "Unsupported OS: ${OS}";;
esac

log "Initializing DevOps Lab on ${PLATFORM}..."

# --- 2. Dependency Check ---
check_dependency() {
    command -v "$1" >/dev/null 2>&1 || return 1
}

DEPS=("git" "docker" "envsubst")
MISSING_DEPS=()

for dep in "${DEPS[@]}"; do
    if ! check_dependency "$dep"; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    log "Some dependencies are missing: ${MISSING_DEPS[*]}"
    if [ "$PLATFORM" == "macos" ]; then
        log "Please install them: brew install ${MISSING_DEPS[*]} (For docker, use Docker Desktop)"
    else
        log "Please install them using your package manager (apt, dnf, etc.)."
    fi
    exit 1
fi

# --- 3. Environment Setup ---
if [ ! -f "$ROOT_ENV" ]; then
    error "Root '.env' file not found at $ROOT_ENV!"
fi

log "Generating service environment variables..."
count=0
for service in "$SERVICES_DIR"/*; do
    if [ -d "$service" ]; then
        service_name=$(basename "$service")
        env_template="$service/.env.template"
        env_file="$service/.env"

        if [ -f "$env_template" ]; then
            # Using subshell to source and envsubst to avoid polluting current shell
            (
                set -a
                # shellcheck disable=SC1090
                source "$ROOT_ENV"
                set +a
                
                # Extract defined variables from template to prevent envsubst from mangling other '$' chars
                VARS_TO_SUBST=$(grep -oE '\$\{?[A-Z0-9_]+\}?' "$env_template" | sort -u | tr -d '${}' | sed 's/^/$/' | tr '\n' ',' | sed 's/,$//')
                
                if [ -z "$VARS_TO_SUBST" ]; then
                    cp "$env_template" "$env_file"
                else
                    envsubst "$VARS_TO_SUBST" < "$env_template" > "$env_file"
                fi
            )
            log "✅ $service_name: Created/Updated .env"
            ((count++))
        fi
    fi
done
log "Initialization complete! ($count files created)"

# --- 4. Docker Network ---
if docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    log "Docker network exists: ${NETWORK_NAME}"
else
    log "Creating Docker network: ${NETWORK_NAME}"
    docker network create "${NETWORK_NAME}"
fi

echo ""
log "Setup complete! Happy Coding! 🐳"
echo "Next steps: docker compose -f services/traefik/docker-compose.yml up -d"
