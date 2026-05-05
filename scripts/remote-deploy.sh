#!/usr/bin/env bash
set -euo pipefail

REMOTE_PATH="${1:?missing REMOTE_PATH}"
SERVICE_NAME="${2:?missing SERVICE_NAME}"
DEBUG_FLAG="${3:-false}"
HEALTHCHECK_CMD="${4:-}"

if [ "${DEBUG_FLAG}" = "true" ]; then
  set -x
fi

cd "${REMOTE_PATH}"
docker compose pull
docker compose up -d --remove-orphans
docker compose ps

if [ -n "${HEALTHCHECK_CMD}" ]; then
  echo "[REMOTE] Running healthcheck for ${SERVICE_NAME}"
  eval "${HEALTHCHECK_CMD}"
fi

echo "Deployment of ${SERVICE_NAME} completed successfully"