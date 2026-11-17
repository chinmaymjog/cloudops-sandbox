#!/usr/bin/env bash
# End-to-end test: bring up the stacks on a throwaway Docker host (a CI runner),
# check every container stays up, Postgres is healthy and each web UI answers
# through Traefik, then tear everything down including volumes.
#
# Refuses to run if a .env already exists, so it can never touch a real setup.
# pi-hole is skipped: it binds port 53, which a CI runner already uses.
set -euo pipefail

cd "$(dirname "$0")/.."
STACKS="${E2E_STACKS:-pgsql traefik prometheus grafana n8n portainer wud}"
DOMAIN="127.0.0.1.nip.io"

if [ -e .env ]; then
  echo "Refusing to run: .env exists (this script is for throwaway hosts only)." >&2
  exit 2
fi

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "==> FAILED (exit $status); container state and logs:"
    docker ps -a --format 'table {{.Names}}\t{{.Status}}' || true
    for c in $(docker ps -a --format '{{.Names}}'); do
      echo "---- $c"; docker logs --tail 40 "$c" 2>&1 || true
    done
  fi
  echo "==> tear down"
  for s in $STACKS; do
    docker compose --env-file .env -f "stacks/$s/docker-compose.yml" down -v --remove-orphans >/dev/null 2>&1 || true
  done
  docker network rm control-plane >/dev/null 2>&1 || true
  rm -f .env
}
trap cleanup EXIT

echo "==> generate a throwaway .env"
while IFS= read -r line; do
  if [[ "$line" == *=TODO ]]; then
    printf '%s=%s\n' "${line%%=*}" "$(openssl rand -hex 16)"
  else
    printf '%s\n' "$line"
  fi
done < .env.template > .env

# Follow the README order: start Postgres, create the per-app roles and
# databases, then start everything else (n8n and Grafana need their database).
echo "==> make up: pgsql"
make up STACKS=pgsql

echo "==> wait for postgres to be healthy"
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' postgresql 2>/dev/null)" = "healthy" ] && break
  sleep 3
done
[ "$(docker inspect -f '{{.State.Health.Status}}' postgresql)" = "healthy" ] \
  || { echo "FAIL: postgresql not healthy"; exit 1; }

echo "==> create app databases (README step 2)"
set -a; . ./.env; set +a
for app in n8n grafana; do
  case " $STACKS " in *" $app "*) ;; *) continue ;; esac
  pw_var="$(printf '%s' "$app" | tr '[:lower:]' '[:upper:]')_DB_PASSWORD"
  docker exec postgresql psql -U postgres -v ON_ERROR_STOP=1 \
    -c "CREATE USER $app WITH PASSWORD '${!pw_var}';" \
    -c "CREATE DATABASE $app OWNER $app;"
done

rest="${STACKS//pgsql/}"
echo "==> make up:$rest"
make up STACKS="$rest"

# Each web UI must answer through Traefik (Host-based routing, self-signed TLS).
# 404 means Traefik has no router for the host; 502/503 means the backend is down.
check() {
  host="$1"; ok="$2"; code=000
  for _ in $(seq 1 40); do
    code="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 \
      --resolve "$host.$DOMAIN:443:127.0.0.1" "https://$host.$DOMAIN/" || true)"
    case " $ok " in *" $code "*) echo "ok   $host -> $code"; return 0 ;; esac
    sleep 5
  done
  echo "FAIL $host -> $code (wanted one of: $ok)"; return 1
}

echo "==> web UIs through Traefik"
failed=0
for s in $STACKS; do
  case "$s" in
    prometheus) check prometheus "200 302 303 307" || failed=1 ;;
    grafana)    check grafana    "200 302 303 307" || failed=1 ;;
    n8n)        check n8n        "200 302 303 307" || failed=1 ;;
    portainer)  check portainer  "200 302 303 307" || failed=1 ;;
    wud)        check wud        "200 302 303 307" || failed=1 ;;
    traefik)    check traefik    "200 302 303 307 401" || failed=1 ;;
  esac
done
[ "$failed" -eq 0 ] || exit 1

echo "==> no container exited or is restarting"
bad="$(docker ps -a --filter status=exited --filter status=restarting --filter status=dead --format '{{.Names}} ({{.Status}})')"
if [ -n "$bad" ]; then echo "FAIL:"; echo "$bad"; exit 1; fi

echo "OK: end-to-end checks passed"
