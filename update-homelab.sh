#!/bin/bash

HOMELAB_DIR="/srv/docker"

echo "========================================"
echo "Homelab Update Script"
echo "========================================"

echo ""
echo "[1/11] Updating Nginx Proxy Manager..."
cd "$HOMELAB_DIR/npm"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[2/11] Updating Portainer..."
cd "$HOMELAB_DIR/portainer"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[3/11] Updating PostgreSQL..."
cd "$HOMELAB_DIR/postgres"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[4/11] Updating MariaDB..."
cd "$HOMELAB_DIR/mariadb"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[5/11] Updating WUD (What's Up Docker)..."
cd "$HOMELAB_DIR/wud"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[6/11] Updating Media Stack..."
cd "$HOMELAB_DIR/stacks/media"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[7/11] Updating Home Assistant..."
cd "$HOMELAB_DIR/stacks/homeassistant"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[8/11] Updating Whoami..."
cd "$HOMELAB_DIR/stacks/whoami"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[9/11] Updating Plausible..."
cd "$HOMELAB_DIR/stacks/plausible"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[10/11] Updating Outline..."
cd "$HOMELAB_DIR/stacks/outline"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[11/11] Upgrading Coolify..."
bash /data/coolify/source/upgrade.sh

# cd "$HOMELAB_DIR/stacks/filewizard"
# docker compose pull && docker compose up -d --force-recreate

echo ""
echo "Cleaning up old images..."
docker image prune -f

echo ""
echo "========================================"
echo "Update complete!"
echo "========================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
