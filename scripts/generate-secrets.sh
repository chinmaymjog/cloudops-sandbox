#!/usr/bin/env bash
set -Eeuo pipefail

# CloudOps-Sandbox - Secret Generator
# Fills in random values for any root .env password/key that still has its
# .env.template placeholder value. Already-customized values are left alone.

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
ROOT_ENV="$BASE_DIR/.env"
TEMPLATE="$BASE_DIR/.env.template"

log() { printf '🔐 %s\n' "$*"; }
error() { printf '❌ Error: %s\n' "$*" >&2; exit 1; }

[[ -f "$ROOT_ENV" ]] || error ".env not found at $ROOT_ENV. Run 'cp .env.template .env' first."
[[ -f "$TEMPLATE" ]] || error ".env.template not found at $TEMPLATE"
command -v openssl >/dev/null 2>&1 || error "openssl is required to generate secrets."

# Placeholder values for these are read from .env.template at runtime, so
# this list has one source of truth for what "still default" means.
VARS_32_HEX_CHARS=(
    POSTGRES_PASSWORD
    N8N_DB_PASSWORD
    GRAFANA_DB_PASSWORD
    GRAFANA_ADMIN_PASSWORD
)
VARS_64_HEX_CHARS=(
    N8N_ENCRYPTION_KEY
)

read_value() {
    local name=$1 file=$2
    grep -E "^${name}=" "$file" | head -n1 | cut -d'=' -f2-
}

generated=0
skipped=0

fill_if_default() {
    local name=$1 byte_len=$2
    local placeholder current value tmp

    placeholder=$(read_value "$name" "$TEMPLATE")
    current=$(read_value "$name" "$ROOT_ENV")

    if [[ -z "$current" ]]; then
        log "⚠️  $name not found in .env; skipping"
        return
    fi

    if [[ "$current" != "$placeholder" ]]; then
        skipped=$((skipped + 1))
        return
    fi

    value=$(openssl rand -hex "$byte_len")
    tmp=$(mktemp)
    sed "s|^${name}=.*|${name}=${value}|" "$ROOT_ENV" > "$tmp" && mv "$tmp" "$ROOT_ENV"
    log "Generated $name"
    generated=$((generated + 1))
}

for name in "${VARS_32_HEX_CHARS[@]}"; do
    fill_if_default "$name" 16
done

for name in "${VARS_64_HEX_CHARS[@]}"; do
    fill_if_default "$name" 32
done

echo ""
log "Done. Generated $generated secret(s); left $skipped already-customized value(s) untouched."
if [[ $generated -gt 0 ]]; then
    log "Run 'make setup' to propagate the new values into stack env files."
fi
