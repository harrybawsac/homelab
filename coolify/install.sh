#!/bin/bash
set -euo pipefail

# =============================================================================
# Coolify Manual Installation Script
# Run as root on your homelab server.
# Safe to re-run: all steps are idempotent.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOLIFY_BASE="/data/coolify"
COOLIFY_SOURCE="${COOLIFY_BASE}/source"
SSH_KEY_PATH="${COOLIFY_BASE}/ssh/keys/id.root@host.docker.internal"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# -----------------------------------------------------------------------------
# 0. Preflight checks
# -----------------------------------------------------------------------------
[[ "$(id -u)" -eq 0 ]] || error "This script must be run as root (try: sudo bash $0)"

command -v docker >/dev/null 2>&1 || error "Docker is not installed. Install Docker Engine 24+ first: https://docs.docker.com/engine/install/"
command -v curl   >/dev/null 2>&1 || error "curl is not installed. Install it first."
command -v openssl >/dev/null 2>&1 || error "openssl is not installed. Install it first."

info "Preflight checks passed."

# -----------------------------------------------------------------------------
# 1. Create directories
# -----------------------------------------------------------------------------
info "Step 1/8 — Creating directories under ${COOLIFY_BASE}..."
mkdir -p "${COOLIFY_BASE}"/{source,ssh,applications,databases,backups,services,proxy,webhooks-during-maintenance}
mkdir -p "${COOLIFY_BASE}/ssh"/{keys,mux}
mkdir -p "${COOLIFY_BASE}/proxy/dynamic"
info "Directories ready."

# -----------------------------------------------------------------------------
# 2. Generate SSH key (skip if already exists)
# -----------------------------------------------------------------------------
info "Step 2/8 — SSH key setup..."
if [[ -f "${SSH_KEY_PATH}" ]]; then
    warn "SSH key already exists at ${SSH_KEY_PATH}, skipping generation."
else
    ssh-keygen -f "${SSH_KEY_PATH}" -t ed25519 -N '' -C root@coolify
    info "SSH key generated."
fi

PUBKEY="$(cat "${SSH_KEY_PATH}.pub")"
AUTHORIZED_KEYS="${HOME}/.ssh/authorized_keys"
mkdir -p "${HOME}/.ssh"
touch "${AUTHORIZED_KEYS}"
if grep -qF "${PUBKEY}" "${AUTHORIZED_KEYS}"; then
    warn "Public key already in ${AUTHORIZED_KEYS}, skipping."
else
    echo "${PUBKEY}" >> "${AUTHORIZED_KEYS}"
    info "Public key added to ${AUTHORIZED_KEYS}."
fi
chmod 600 "${AUTHORIZED_KEYS}"

# -----------------------------------------------------------------------------
# 3. Download configuration files from Coolify CDN
# -----------------------------------------------------------------------------
info "Step 3/8 — Downloading Coolify configuration files..."
curl -fsSL https://cdn.coollabs.io/coolify/docker-compose.yml      -o "${COOLIFY_SOURCE}/docker-compose.yml"
curl -fsSL https://cdn.coollabs.io/coolify/docker-compose.prod.yml -o "${COOLIFY_SOURCE}/docker-compose.prod.yml"
curl -fsSL https://cdn.coollabs.io/coolify/upgrade.sh              -o "${COOLIFY_SOURCE}/upgrade.sh"

# Only download .env if it doesn't exist yet — preserve any existing secrets
if [[ ! -f "${COOLIFY_SOURCE}/.env" ]]; then
    curl -fsSL https://cdn.coollabs.io/coolify/.env.production -o "${COOLIFY_SOURCE}/.env"
    info "Downloaded .env template."
else
    warn ".env already exists, skipping download to preserve existing secrets."
fi
info "Configuration files ready."

# -----------------------------------------------------------------------------
# 4. Set permissions
# -----------------------------------------------------------------------------
info "Step 4/8 — Setting permissions..."
chown -R 9999:root "${COOLIFY_BASE}"
chmod -R 700 "${COOLIFY_BASE}"
info "Permissions set."

# -----------------------------------------------------------------------------
# 5. Generate secrets (only on first install — guard against overwriting)
# -----------------------------------------------------------------------------
info "Step 5/8 — Generating secrets..."
CURRENT_APP_ID="$(grep '^APP_ID=' "${COOLIFY_SOURCE}/.env" | cut -d= -f2)"

if [[ -z "${CURRENT_APP_ID}" || "${CURRENT_APP_ID}" == "some-random-string" || "${CURRENT_APP_ID}" == "change-me" ]]; then
    sed -i "s|APP_ID=.*|APP_ID=$(openssl rand -hex 16)|g"                  "${COOLIFY_SOURCE}/.env"
    sed -i "s|APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|g"      "${COOLIFY_SOURCE}/.env"
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -base64 32)|g"     "${COOLIFY_SOURCE}/.env"
    sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$(openssl rand -base64 32)|g" "${COOLIFY_SOURCE}/.env"
    sed -i "s|PUSHER_APP_ID=.*|PUSHER_APP_ID=$(openssl rand -hex 32)|g"    "${COOLIFY_SOURCE}/.env"
    sed -i "s|PUSHER_APP_KEY=.*|PUSHER_APP_KEY=$(openssl rand -hex 32)|g"  "${COOLIFY_SOURCE}/.env"
    sed -i "s|PUSHER_APP_SECRET=.*|PUSHER_APP_SECRET=$(openssl rand -hex 32)|g" "${COOLIFY_SOURCE}/.env"
    info "Secrets generated and written to .env."
else
    warn "APP_ID is already set — skipping secret generation (existing install)."
fi

# -----------------------------------------------------------------------------
# 6. Create Docker networks
# -----------------------------------------------------------------------------
info "Step 6/8 — Creating Docker networks..."
docker network create --attachable coolify 2>/dev/null && info "Created 'coolify' network." \
    || warn "'coolify' network already exists, skipping."

docker network create proxy 2>/dev/null && info "Created 'proxy' network." \
    || warn "'proxy' network already exists, skipping."

# -----------------------------------------------------------------------------
# 7. Copy custom compose overlay
# -----------------------------------------------------------------------------
info "Step 7/8 — Installing docker-compose.custom.yml overlay..."
cp "${SCRIPT_DIR}/docker-compose.custom.yml" "${COOLIFY_SOURCE}/docker-compose.custom.yml"
# Ensure Coolify process can read it
chown 9999:root "${COOLIFY_SOURCE}/docker-compose.custom.yml"
chmod 600 "${COOLIFY_SOURCE}/docker-compose.custom.yml"
info "Custom overlay installed."

# -----------------------------------------------------------------------------
# 8. Start Coolify
# -----------------------------------------------------------------------------
info "Step 8/8 — Starting Coolify..."
docker compose \
    --env-file "${COOLIFY_SOURCE}/.env" \
    -f "${COOLIFY_SOURCE}/docker-compose.yml" \
    -f "${COOLIFY_SOURCE}/docker-compose.prod.yml" \
    -f "${COOLIFY_SOURCE}/docker-compose.custom.yml" \
    up -d --pull always --remove-orphans --force-recreate

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN} Coolify is starting!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "  Admin UI (direct):  http://$(hostname -I | awk '{print $1}'):8000"
echo "  Proxy admin ports:  http://$(hostname -I | awk '{print $1}'):8080 (HTTP)"
echo "                      https://$(hostname -I | awk '{print $1}'):8081 (HTTPS)"
echo ""
echo "  IMPORTANT: Go to the admin UI now and create your admin account"
echo "  before anyone else accesses the registration page!"
echo ""
echo "  Next steps:"
echo "  1. Create your admin account at the URL above"
echo "  2. In NPM, add a proxy host:"
echo "     - Domain:   coolify.yourdomain.com"
echo "     - Forward:  coolify:8000 (HTTP, no SSL on container)"
echo ""
