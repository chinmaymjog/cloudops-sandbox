#!/usr/bin/env bash
set -Eeuo pipefail

# Docker lab VM bootstrap for Debian/Ubuntu.
# Idempotent by design: safe to rerun.

DEPLOY_DIR="${DEPLOY_DIR:-/services}"
REPO_URL="${REPO_URL:-}"
REPO_BRANCH="${REPO_BRANCH:-develop}"
NETWORK_NAME="${NETWORK_NAME:-control-plane}"
DEPLOY_USER="${DEPLOY_USER:-manage}"
DEPLOY_HOME="$(getent passwd "${DEPLOY_USER}" | cut -d: -f6 || true)"
if [[ -z "${DEPLOY_HOME}" ]]; then
  DEPLOY_HOME="/home/${DEPLOY_USER}"
fi
GITLAB_KEY_PATH="${GITLAB_KEY_PATH:-${DEPLOY_HOME}/.ssh/id_ed25519_gitlab}"
ENABLE_UFW="${ENABLE_UFW:-false}"

log() {
  printf '[bootstrap] %s\n' "$*"
}

run_as_deploy_user() {
  sudo -H -u "${DEPLOY_USER}" "$@"
}

ensure_path_owner() {
  local path="$1"
  local recursive="${2:-false}"

  if [[ ! -e "${path}" ]]; then
    return
  fi

  if [[ "${recursive}" == "true" ]]; then
    chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${path}"
  else
    chown "${DEPLOY_USER}:${DEPLOY_USER}" "${path}"
  fi
}

ensure_git_safe_directory() {
  local current_home

  current_home="$(run_as_deploy_user bash -lc 'printf %s "$HOME"')"
  if [[ -z "${current_home}" ]]; then
    echo "Could not determine home directory for ${DEPLOY_USER}" >&2
    exit 1
  fi

  if ! run_as_deploy_user git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "${DEPLOY_DIR}"; then
    log "Adding git safe.directory for ${DEPLOY_USER}: ${DEPLOY_DIR}"
    run_as_deploy_user git config --global --add safe.directory "${DEPLOY_DIR}"
  fi
}

ensure_repo_control_permissions() {
  ensure_path_owner "${DEPLOY_DIR}"
  ensure_path_owner "${DEPLOY_DIR}/.git" true
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must run as root." >&2
    exit 1
  fi
}

check_os() {
  if [[ ! -f /etc/os-release ]]; then
    echo "Cannot detect OS: /etc/os-release missing." >&2
    exit 1
  fi

  . /etc/os-release
  case "${ID:-}" in
    ubuntu|debian)
      ;;
    *)
      echo "Unsupported OS: ${ID:-unknown}. This script supports Debian/Ubuntu." >&2
      exit 1
      ;;
  esac
}

install_base_packages() {
  log "Installing base packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gettext-base \
    git \
    gnupg \
    jq \
    lsb-release \
    openssh-client \
    software-properties-common
}

install_docker_if_missing() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed"
  else
    log "Installing Docker Engine and Compose plugin"
    curl -fsSL https://get.docker.com | sh
  fi

  systemctl enable docker
  systemctl restart docker

  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose plugin is not available after install." >&2
    exit 1
  fi
}

setup_gitlab_ssh_key() {
  local ssh_dir
  local legacy_root_key

  ssh_dir="$(dirname "${GITLAB_KEY_PATH}")"
  legacy_root_key="/root/.ssh/id_ed25519_gitlab"

  mkdir -p "${ssh_dir}"
  chmod 700 "${ssh_dir}"
  chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${ssh_dir}"

  # Backward-compatibility: migrate an existing root key to deploy user.
  if [[ "${DEPLOY_USER}" != "root" && ! -f "${GITLAB_KEY_PATH}" && -f "${legacy_root_key}" ]]; then
    log "Migrating existing root deploy key to ${DEPLOY_USER}"
    install -m 600 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${legacy_root_key}" "${GITLAB_KEY_PATH}"
    if [[ -f "${legacy_root_key}.pub" ]]; then
      install -m 644 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${legacy_root_key}.pub" "${GITLAB_KEY_PATH}.pub"
    fi
  fi

  if [[ ! -f "${GITLAB_KEY_PATH}" ]]; then
    log "Generating GitLab deploy key: ${GITLAB_KEY_PATH}"
    run_as_deploy_user ssh-keygen -t ed25519 -C "vm-deploy-key" -f "${GITLAB_KEY_PATH}" -N ""
  else
    log "GitLab deploy key already exists: ${GITLAB_KEY_PATH}"
  fi

  run_as_deploy_user touch "${ssh_dir}/config"
  if ! grep -q "IdentityFile ${GITLAB_KEY_PATH}" "${ssh_dir}/config"; then
    cat >> "${ssh_dir}/config" <<EOF
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ${GITLAB_KEY_PATH}
  IdentitiesOnly yes
EOF
  fi
  chmod 600 "${ssh_dir}/config"
  chown "${DEPLOY_USER}:${DEPLOY_USER}" "${ssh_dir}/config"

  run_as_deploy_user touch "${ssh_dir}/known_hosts"
  if ! run_as_deploy_user ssh-keygen -F gitlab.com -f "${ssh_dir}/known_hosts" >/dev/null 2>&1; then
    run_as_deploy_user bash -lc "ssh-keyscan -H gitlab.com >> '${ssh_dir}/known_hosts'"
  fi
  chmod 644 "${ssh_dir}/known_hosts"
  chown "${DEPLOY_USER}:${DEPLOY_USER}" "${ssh_dir}/known_hosts"

  log "Add this public key to GitLab Deploy Keys (read-only) for ${DEPLOY_USER}"
  echo "-----BEGIN GITLAB DEPLOY PUBLIC KEY-----"
  cat "${GITLAB_KEY_PATH}.pub"
  echo "-----END GITLAB DEPLOY PUBLIC KEY-----"
}

ensure_repo_checkout() {
  mkdir -p "${DEPLOY_DIR}"
  ensure_path_owner "${DEPLOY_DIR}"

  if [[ -d "${DEPLOY_DIR}/.git" ]]; then
    ensure_repo_control_permissions
    ensure_git_safe_directory

    if [[ -n "${REPO_URL}" ]]; then
      if run_as_deploy_user git -C "${DEPLOY_DIR}" remote get-url origin >/dev/null 2>&1; then
        current_origin="$(run_as_deploy_user git -C "${DEPLOY_DIR}" remote get-url origin || true)"
        if [[ "${current_origin}" != "${REPO_URL}" ]]; then
          log "Updating origin remote in ${DEPLOY_DIR}"
          run_as_deploy_user git -C "${DEPLOY_DIR}" remote set-url origin "${REPO_URL}"
        fi
      else
        log "Adding origin remote in ${DEPLOY_DIR}"
        run_as_deploy_user git -C "${DEPLOY_DIR}" remote add origin "${REPO_URL}"
      fi

      log "Updating existing repo in ${DEPLOY_DIR}"
      run_as_deploy_user git -C "${DEPLOY_DIR}" fetch origin
      run_as_deploy_user git -C "${DEPLOY_DIR}" checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}"
      run_as_deploy_user git -C "${DEPLOY_DIR}" reset --hard "origin/${REPO_BRANCH}"
      run_as_deploy_user git -C "${DEPLOY_DIR}" clean -fd
    else
      log "Existing local git repo found in ${DEPLOY_DIR}; REPO_URL not set, skipping remote sync"
    fi
    return
  fi

  if [[ -z "${REPO_URL}" ]]; then
    log "REPO_URL not set; initializing local git repo in ${DEPLOY_DIR}"
    run_as_deploy_user git -C "${DEPLOY_DIR}" init
    ensure_repo_control_permissions
    ensure_git_safe_directory
    return
  fi

  if [[ -z "$(ls -A "${DEPLOY_DIR}")" ]]; then
    log "Cloning repo ${REPO_URL} into ${DEPLOY_DIR}"
    run_as_deploy_user git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${DEPLOY_DIR}"
    ensure_repo_control_permissions
    ensure_git_safe_directory
    return
  fi

  log "${DEPLOY_DIR} is non-empty; initializing git and attaching origin"
  run_as_deploy_user git -C "${DEPLOY_DIR}" init
  run_as_deploy_user git -C "${DEPLOY_DIR}" remote remove origin >/dev/null 2>&1 || true
  run_as_deploy_user git -C "${DEPLOY_DIR}" remote add origin "${REPO_URL}"
  run_as_deploy_user git -C "${DEPLOY_DIR}" fetch origin
  run_as_deploy_user git -C "${DEPLOY_DIR}" checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}"
  ensure_repo_control_permissions
  ensure_git_safe_directory
}

ensure_docker_network() {
  if docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    log "Docker network exists: ${NETWORK_NAME}"
  else
    log "Creating Docker network: ${NETWORK_NAME}"
    docker network create "${NETWORK_NAME}"
  fi
}

ensure_service_directories() {
  local service_root
  local service

  service_root="${DEPLOY_DIR}/services"
  mkdir -p "${service_root}"

  for service in traefik grafana mysql n8n pgsql portainer prometheus wud; do
    mkdir -p "${service_root}/${service}"
  done

  mkdir -p "${service_root}/traefik/certs" "${service_root}/traefik/log"
  mkdir -p "${service_root}/grafana/data"
  mkdir -p "${service_root}/mysql/data"
  mkdir -p "${service_root}/n8n/data"
  mkdir -p "${service_root}/pgsql/data"
  mkdir -p "${service_root}/portainer/data"
  mkdir -p "${service_root}/prometheus/data"

  log "Service directories prepared under ${service_root}"
}

configure_firewall_if_requested() {
  if [[ "${ENABLE_UFW}" != "true" ]]; then
    log "ENABLE_UFW=false; skipping firewall config"
    return
  fi

  if ! command -v ufw >/dev/null 2>&1; then
    apt-get install -y ufw
  fi

  log "Configuring UFW"
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
}

print_summary() {
  log "Bootstrap complete"
  echo ""
  echo "Next steps:"
  echo "1) Add deploy key above to GitLab (repo Deploy Key or bot account key)."
  echo "2) Set CI variables: SSH_PRIVATE_KEY, SSH_KNOWN_HOSTS, SSH_USER, SSH_PORT, CONTROLLER."
  echo "3) Confirm deploy user and key path: ${DEPLOY_USER} / ${GITLAB_KEY_PATH}"
  echo "4) Confirm repo path on VM: ${DEPLOY_DIR}"
  echo "5) Run first deployment from GitLab CI."
}

main() {
  require_root
  check_os
  install_base_packages
  install_docker_if_missing
  setup_gitlab_ssh_key
  ensure_repo_checkout
  ensure_docker_network
  ensure_service_directories
  configure_firewall_if_requested
  print_summary
}

main "$@"
