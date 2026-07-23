#!/bin/bash

HOMELAB_DIR="/srv/docker"

echo "========================================"
echo "Homelab Update Script"
echo "========================================"

echo ""
echo "[1/12] Updating Nginx Proxy Manager..."
cd "$HOMELAB_DIR/npm"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[2/12] Updating Portainer..."
cd "$HOMELAB_DIR/portainer"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[3/12] Updating PostgreSQL..."
cd "$HOMELAB_DIR/postgres"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[4/12] Updating MariaDB..."
cd "$HOMELAB_DIR/mariadb"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[5/12] Updating WUD (What's Up Docker?)..."
cd "$HOMELAB_DIR/wud"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[6/12] Updating Media Stack..."
cd "$HOMELAB_DIR/stacks/media"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[7/12] Updating Home Assistant..."
cd "$HOMELAB_DIR/stacks/homeassistant"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[8/12] Updating Whoami..."
cd "$HOMELAB_DIR/stacks/whoami"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[9/12] Updating Plausible..."
cd "$HOMELAB_DIR/stacks/plausible"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[10/12] Updating Outline..."
cd "$HOMELAB_DIR/stacks/outline"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[11/12] Updating Agent Gateway..."
cd "$HOMELAB_DIR/stacks/agentgateway"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "[12/12] Updating Hermes Agent..."
cd "$HOMELAB_DIR/stacks/hermes"
docker compose pull && docker compose up -d --force-recreate

echo ""
echo "Cleaning up old images..."
docker image prune -f

echo ""
echo "========================================"
echo "Update complete!"
echo "========================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
