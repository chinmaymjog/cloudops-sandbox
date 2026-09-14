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

# name:generator - placeholder values are read from .env.template at runtime
# so this list has one source of truth for what "still default" means.
SECRET_VARS=(
    "POSTGRES_PASSWORD:hex16"
    "N8N_DB_PASSWORD:hex16"
    "GRAFANA_DB_PASSWORD:hex16"
    "MYSQL_ROOT_PASSWORD:hex16"
    "N8N_ENCRYPTION_KEY:hex32"
    "KEYCLOAK_ADMIN_PASSWORD:hex16"
    "KEYCLOAK_DB_PASSWORD:hex16"
)

read_value() {
    local name=$1 file=$2
    grep -E "^${name}=" "$file" | head -n1 | cut -d'=' -f2-
}

generated=0
skipped=0

for entry in "${SECRET_VARS[@]}"; do
    IFS=':' read -r name kind <<< "$entry"
    placeholder=$(read_value "$name" "$TEMPLATE")
    current=$(read_value "$name" "$ROOT_ENV")

    if [[ -z "$current" ]]; then
        log "⚠️  $name not found in .env; skipping"
        continue
    fi

    if [[ "$current" != "$placeholder" ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    case "$kind" in
        hex16) value=$(openssl rand -hex 16) ;;
        hex32) value=$(openssl rand -hex 32) ;;
    esac

    tmp=$(mktemp)
    sed "s|^${name}=.*|${name}=${value}|" "$ROOT_ENV" > "$tmp" && mv "$tmp" "$ROOT_ENV"
    log "Generated $name"
    generated=$((generated + 1))
done

echo ""
log "Done. Generated $generated secret(s); left $skipped already-customized value(s) untouched."
if [[ $generated -gt 0 ]]; then
    log "Run 'make setup' to propagate the new values into stack env files."
fi
