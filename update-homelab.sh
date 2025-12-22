#!/bin/bash

HOMELAB_DIR="/srv/docker"

echo "========================================"
echo "Homelab Update Script"
echo "========================================"

echo ""
echo "[1/10] Updating Nginx Proxy Manager..."
cd "$HOMELAB_DIR/npm"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[2/10] Updating Portainer..."
cd "$HOMELAB_DIR/portainer"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[3/10] Updating PostgreSQL..."
cd "$HOMELAB_DIR/postgres"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[4/10] Updating MariaDB..."
cd "$HOMELAB_DIR/mariadb"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[5/10] Updating WUD (What's Up Docker)..."
cd "$HOMELAB_DIR/wud"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[6/10] Updating Media Stack..."
cd "$HOMELAB_DIR/stacks/media"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[7/10] Updating Home Assistant..."
cd "$HOMELAB_DIR/stacks/homeassistant"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[8/10] Updating Application Stacks..."
cd "$HOMELAB_DIR/stacks/matomo"
docker compose pull && docker compose up -d --force-recreate

cd "$HOMELAB_DIR/stacks/whoami"
docker compose pull && docker compose up -d --force-recreate

cd "$HOMELAB_DIR/stacks/plausible"
docker compose pull && docker compose up -d --force-recreate

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
