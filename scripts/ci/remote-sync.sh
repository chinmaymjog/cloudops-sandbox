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
echo "[REMOTE] Repo owner is ${owner}; expected deploy user ${REMOTE_OWNER}"

if [ ! -w "${DEPLOY_DIR}" ]; then
  echo "[REMOTE] ${DEPLOY_DIR} is not writable by deploy user."
  echo "[REMOTE] Fix once during bootstrap/manual prep, then rerun deploy."
  exit 1
fi

if ! git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "${DEPLOY_DIR}"; then
  echo "[REMOTE] Adding git safe.directory for ${REMOTE_OWNER}: ${DEPLOY_DIR}"
  git config --global --add safe.directory "${DEPLOY_DIR}"
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