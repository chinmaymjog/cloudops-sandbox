#!/usr/bin/env bash
set -Eeuo pipefail

# Integration test for DB onboarding env wiring.
# It proves that updating init scripts is not sufficient when the DB password
# variable is not present in the running DB container environment.

TEST_NAME="db-onboarding-env-wiring"
CONTAINER="${TEST_NAME}-$$"
IMAGE="postgres:16"
APP_PASSWORD="demo_app_secret"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_postgres() {
  local retries=60
  while (( retries > 0 )); do
    if docker exec "$CONTAINER" pg_isready -U postgres >/dev/null 2>&1; then
      return 0
    fi
    retries=$((retries - 1))
    sleep 1
  done
  echo "Timed out waiting for test postgres container" >&2
  return 1
}

get_demo_password_hash() {
  docker exec "$CONTAINER" psql -U postgres -d postgres -tAc \
    "SELECT COALESCE(rolpassword, 'NULL') FROM pg_authid WHERE rolname='demo';"
}

demo_role_exists() {
  local exists
  exists="$(docker exec "$CONTAINER" psql -U postgres -d postgres -tAc "SELECT COUNT(*) FROM pg_roles WHERE rolname='demo';" | tr -d '[:space:]')"
  [[ "$exists" == "1" ]]
}

wait_for_demo_role() {
  local retries=30
  while (( retries > 0 )); do
    if demo_role_exists; then
      return 0
    fi
    retries=$((retries - 1))
    sleep 1
  done
  return 1
}

echo "[1/6] Preparing isolated init script"
TMP_DIR="$(mktemp -d)"
INIT_SCRIPT="$TMP_DIR/init-databases.sh"

cat > "$INIT_SCRIPT" <<'EOF'
#!/bin/bash
set -e

create_user_and_database() {
  local database=$1
  local user=$2
  local password=$3

  export PGPASSWORD="${POSTGRES_PASSWORD}"
  psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "postgres" <<-EOSQL
    DO \$$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$user') THEN
        CREATE USER "$user" WITH PASSWORD '$password';
      ELSE
        ALTER USER "$user" WITH PASSWORD '$password';
      END IF;
    END
    \$$;
EOSQL

  psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "postgres" <<-EOSQL
    SELECT 'CREATE DATABASE "$database" OWNER "$user"'
    WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_database WHERE datname = '$database')\gexec
    GRANT ALL PRIVILEGES ON DATABASE "$database" TO "$user";
EOSQL
}

# Simulated newly onboarded service
create_user_and_database "demo" "demo" "${DEMO_DB_PASSWORD}"
EOF

chmod +x "$INIT_SCRIPT"

echo "[2/6] Starting isolated postgres with missing DEMO_DB_PASSWORD"
docker run -d --name "$CONTAINER" \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -v "$INIT_SCRIPT":/docker-entrypoint-initdb.d/init-databases.sh \
  "$IMAGE" >/dev/null

wait_for_postgres

echo "[3/6] Capturing password state after startup with missing DEMO_DB_PASSWORD"
if ! wait_for_demo_role; then
  docker logs "$CONTAINER" --tail 120 >&2 || true
  echo "FAIL: demo role was not created during startup" >&2
  exit 1
fi
HASH_WITH_MISSING_ENV="$(get_demo_password_hash | tr -d '[:space:]')"
if [[ "$HASH_WITH_MISSING_ENV" != "NULL" ]]; then
  echo "FAIL: expected NULL password hash when DEMO_DB_PASSWORD is missing" >&2
  exit 1
fi
echo "PASS: demo role exists (hash captured)"

echo "[4/6] Running sync script without DEMO_DB_PASSWORD (simulates make sync-dbs)"
docker exec "$CONTAINER" bash /docker-entrypoint-initdb.d/init-databases.sh >/dev/null

HASH_AFTER_SYNC_WITHOUT_ENV="$(get_demo_password_hash | tr -d '[:space:]')"
if [[ "$HASH_AFTER_SYNC_WITHOUT_ENV" != "$HASH_WITH_MISSING_ENV" ]]; then
  echo "FAIL: password hash changed unexpectedly without DEMO_DB_PASSWORD" >&2
  exit 1
fi
echo "PASS: sync without env var is insufficient (password state unchanged)"

echo "[5/6] Running sync script with DEMO_DB_PASSWORD passed at runtime"
docker exec -e DEMO_DB_PASSWORD="$APP_PASSWORD" "$CONTAINER" \
  bash /docker-entrypoint-initdb.d/init-databases.sh >/dev/null

echo "[6/6] Verifying password state updates when env var is passed"
HASH_AFTER_SYNC_WITH_ENV="$(get_demo_password_hash | tr -d '[:space:]')"
if [[ "$HASH_AFTER_SYNC_WITH_ENV" == "$HASH_WITH_MISSING_ENV" ]]; then
  echo "FAIL: password hash did not change even after DEMO_DB_PASSWORD was passed" >&2
  exit 1
fi
if [[ "$HASH_AFTER_SYNC_WITH_ENV" == "NULL" ]]; then
  echo "FAIL: password hash is still NULL after passing DEMO_DB_PASSWORD" >&2
  exit 1
fi

echo "PASS: onboarding works only when DB password env is passed into DB runtime/sync context"
echo "Test completed successfully."
