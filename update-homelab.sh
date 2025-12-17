#!/bin/bash

HOMELAB_DIR="/srv/docker"

echo "========================================"
echo "Homelab Update Script"
echo "========================================"

echo ""
echo "[1/8] Updating Nginx Proxy Manager..."
cd "$HOMELAB_DIR/npm"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[2/8] Updating Portainer..."
cd "$HOMELAB_DIR/portainer"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[3/8] Updating PostgreSQL..."
cd "$HOMELAB_DIR/postgres"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[4/8] Updating MariaDB..."
cd "$HOMELAB_DIR/mariadb"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[5/8] Updating WUD (What's Up Docker)..."
cd "$HOMELAB_DIR/wud"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[6/8] Updating Media Stack..."
cd "$HOMELAB_DIR/stacks/media"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[7/8] Updating Home Assistant..."
cd "$HOMELAB_DIR/stacks/homeassistant"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[8/8] Updating Application Stacks..."
cd "$HOMELAB_DIR/stacks/matomo"
docker compose pull && docker compose up -d --force-recreate

cd "$HOMELAB_DIR/stacks/whoami"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "Cleaning up old images..."
docker image prune -f

echo ""
echo "========================================"
echo "Update complete!"
echo "========================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
