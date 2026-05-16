#!/usr/bin/env bash
set -euo pipefail

# CloudOps-Sandbox - Remote Deployment Script
# Intended to be run on the remote VM via SSH.

REMOTE_PATH="${1:?missing REMOTE_PATH}"
STACK_NAME="${2:?missing STACK_NAME}"
DEBUG_FLAG="${3:-false}"
HEALTHCHECK_CMD="${4:-}"

if [ "${DEBUG_FLAG}" = "true" ]; then
  set -x
fi

cd "${REMOTE_PATH}"

# 1. Ensure environment files are generated/updated on the remote host
if [ -f "Makefile" ]; then
  echo "[REMOTE] Running 'make setup' to generate environment files..."
  make setup
fi

# 2. Deploy the specific stack
echo "[REMOTE] Pulling latest images for ${STACK_NAME}..."
docker compose -f "stacks/${STACK_NAME}/docker-compose.yml" pull

echo "[REMOTE] Starting stack: ${STACK_NAME}..."
docker compose -f "stacks/${STACK_NAME}/docker-compose.yml" up -d --remove-orphans

echo "[REMOTE] Stack status:"
docker compose -f "stacks/${STACK_NAME}/docker-compose.yml" ps

# 3. Optional Healthcheck
if [ -n "${HEALTHCHECK_CMD}" ]; then
  echo "[REMOTE] Running healthcheck for ${STACK_NAME}..."
  eval "${HEALTHCHECK_CMD}"
fi

echo "🚀 Deployment of ${STACK_NAME} completed successfully"