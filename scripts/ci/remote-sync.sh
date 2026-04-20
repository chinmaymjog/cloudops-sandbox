#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="${1:?missing DEPLOY_DIR}"
REMOTE_OWNER="${2:?missing REMOTE_OWNER}"
BRANCH="${3:?missing BRANCH}"
DEBUG_FLAG="${4:-false}"

if [ "${DEBUG_FLAG}" = "true" ]; then
  set -x
fi

echo "[REMOTE] Ensuring deploy directory exists: ${DEPLOY_DIR}"
sudo -n mkdir -p "${DEPLOY_DIR}"

owner="$(stat -c '%U:%G' "${DEPLOY_DIR}" 2>/dev/null || true)"
if [ "${owner}" != "${REMOTE_OWNER}:${REMOTE_OWNER}" ]; then
  echo "[REMOTE] Fixing ownership for ${DEPLOY_DIR}"
  sudo -n chown -R "${REMOTE_OWNER}:${REMOTE_OWNER}" "${DEPLOY_DIR}"
fi

if ! sudo -n git config --system --get-all safe.directory 2>/dev/null | grep -Fxq "${DEPLOY_DIR}"; then
  echo "[REMOTE] Adding git safe.directory: ${DEPLOY_DIR}"
  sudo -n git config --system --add safe.directory "${DEPLOY_DIR}"
fi

cd "${DEPLOY_DIR}"
for i in 1 2 3 4 5; do
  echo "[REMOTE] Git sync attempt ${i}/5 on branch ${BRANCH}"
  if git fetch origin && git reset --hard "origin/${BRANCH}" && git clean -fd; then
    echo "[REMOTE] Git sync succeeded"
    exit 0
  fi
  echo "[REMOTE] Git sync failed, retrying in 5s..."
  sleep 5
done

echo "[REMOTE] Git sync failed after 5 attempts"
exit 1