# Homelab Docker Setup

This repository contains Docker Compose configurations for a complete homelab setup including media automation, home automation, reverse proxy, and database services.

## 📋 Table of Contents

- [Overview](#overview)
- [Services](#services)
- [Prerequisites](#prerequisites)
- [Network Architecture](#network-architecture)
- [Getting Started](#getting-started)
- [Managing Services](#managing-services)
- [Updating Services](#updating-services)
- [Troubleshooting](#troubleshooting)
- [Backup and Restore](#backup-and-restore)

## 🏗️ Overview

This homelab setup uses Docker Compose to manage multiple containerized services. The infrastructure is organized into logical stacks:

- **Core Infrastructure**: Nginx Proxy Manager, Portainer, PostgreSQL, MariaDB
- **Monitoring**: WUD (What's Up Docker) for container update tracking
- **Media Stack**: Complete *arr suite for media automation
- **Analytics**: Matomo web analytics
- **Home Automation**: Home Assistant
- **Utilities**: Various helper services

## 🚀 Services

### Core Infrastructure

#### Nginx Proxy Manager (NPM)
- **Purpose**: Reverse proxy with SSL certificate management
- **Location**: `npm/`
- **Ports**: 
  - `80` - HTTP (public)
  - `443` - HTTPS (public)
  - `192.168.2.7:81` - Admin UI (LAN only)
- **Network**: `proxy` (external)

#### Portainer
- **Purpose**: Docker container management UI
- **Location**: `portainer/`
- **Ports**: `192.168.2.7:9443` - Web UI (LAN only)
- **Network**: `proxy` (external)

#### PostgreSQL
- **Purpose**: Database server (for services requiring PostgreSQL)
- **Location**: `postgres/`
- **Ports**: `192.168.2.7:5432` - PostgreSQL (LAN only)
- **Credentials**: 
  - User: `some_user`
  - Password: `fill_in_something`
  - Default DB: `postgres`
- **Network**: `proxy` (external)

#### MariaDB
- **Purpose**: Shared MySQL-compatible database server
- **Location**: `mariadb/`
- **Ports**: `192.168.2.7:3306` - MariaDB (LAN only)
- **Credentials**:
  - Root Password: `fill_in_something`
- **Network**: `proxy` (external)
- **Used by**: Matomo (and other services requiring MySQL/MariaDB)

### Monitoring

#### WUD (What's Up Docker)
- **Purpose**: Monitor Docker containers for available updates
- **Location**: `wud/`
- **Port**: `192.168.2.7:3069` - Web UI (LAN only)
- **Network**: `proxy` (external)
- **Features**:
  - Automatic detection of all running containers
  - Daily update checks (configurable via cron)
  - Web dashboard showing update availability
  - Support for notifications (Discord, Slack, email, etc.)
  - Registry authentication support

### Media Stack

The complete media automation stack in `stacks/media/`:

#### qBittorrent
- **Purpose**: Torrent client
- **Ports**: 
  - `8080` - Web UI
  - `6881` - Torrenting (TCP/UDP)

#### Prowlarr
- **Purpose**: Indexer manager
- **Port**: `9696`
- **Features**: Centralized indexer management for Sonarr/Radarr

#### Sonarr
- **Purpose**: TV show automation
- **Port**: `8989`
- **Media Path**: `./media/tv`

#### Radarr
- **Purpose**: Movie automation
- **Port**: `7878`
- **Media Path**: `./media/movies`

#### Bazarr
- **Purpose**: Subtitle management
- **Port**: `6767`
- **Integrates with**: Sonarr and Radarr

#### FlareSolverr
- **Purpose**: Cloudflare bypass proxy
- **Port**: `8191`
- **Used by**: Prowlarr for protected indexers

**Common Configuration**:
- PUID: `1000`
- PGID: `1000`
- UMASK: `002`
- Timezone: `Europe/Amsterdam`
- Network: `media` (internal)

### Home Automation

#### Home Assistant
- **Location**: `stacks/homeassistant/`
- **Network Mode**: `host` (requires direct network access)
- **Devices**: USB device `/dev/ttyUSB0` (for Zigbee/Z-Wave)
- **Features**: Privileged mode for full hardware access

### Utilities

#### Whoami
- **Location**: `stacks/whoami/`
- **Purpose**: Testing/debugging service
- **Network**: `proxy` (external)

### Analytics

#### Matomo
- **Purpose**: Self-hosted web analytics (Google Analytics alternative)
- **Location**: `stacks/matomo/`
- **Port**: `8090` - Web UI
- **Database**: Uses shared MariaDB instance
- **Network**: `proxy` (external)

## 📦 Prerequisites

### System Requirements

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

### Network Setup

Create the external `proxy` network before starting services:

```bash
docker network create proxy
```

This network allows services to communicate with Nginx Proxy Manager and other infrastructure components.

## 🌐 Network Architecture

```
┌─────────────────────────────────────────────┐
│              Internet (80/443)              │
└─────────────────────┬───────────────────────┘
                      │
        ┌─────────────▼──────────────┐
        │  Nginx Proxy Manager (NPM) │
        │  - Reverse Proxy           │
        │  - SSL/TLS Management      │
        └─────────────┬──────────────┘
                      │
          ┌───────────┴───────────┐
          │   'proxy' network     │
          │   (external/shared)   │
          └───────────┬───────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼─────┐  ┌──────▼──────┐  ┌───▼────┐  ┌────▼────┐  ┌──▼──┐  ┌───▼───┐
│Portainer│  │ PostgreSQL  │  │MariaDB │  │ Matomo  │  │ WUD │  │Whoami │
└─────────┘  └─────────────┘  └────────┘  └─────────┘  └─────┘  └───────┘

┌──────────────────────────────────────────────────────────────┐
│              Media Stack ('media' network)                   │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ qBittorrent│  │ Prowlarr │  │  Sonarr  │  │  Radarr  │    │
│  └─────┬──────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│        │              │             │             │          │
│        │         ┌────▼───────┐ ┌───▼─────────────▼──┐       │
│        │         │Flaresolverr│ │       Bazarr       │       │
│        └─────────┴────────────┴─┴────────────────────┘       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              Home Assistant (host network)                   │
│  - Direct network access                                     │
│  - Hardware device access (/dev/ttyUSB0)                     │
└──────────────────────────────────────────────────────────────┘
```

**Network Isolation**:
- **`proxy` network**: External network for infrastructure and internet-facing services
- **`media` network**: Internal network for media automation services
- **Host network**: Used by Home Assistant for direct hardware and network access

**Security Notes**:
- Public services (80, 443) are accessible from the internet
- Admin interfaces (81, 9443, 5432) are bound to LAN IP `192.168.2.7`
- Media services use internal networking, expose ports for LAN access only

## 🎯 Getting Started

### Initial Setup

1. **Clone or navigate to the homelab directory**:
   ```bash
   cd /home/projects/homelab
   ```

2. **Create the external proxy network**:
   ```bash
   docker network create proxy
   ```

3. **Review and update configuration**:
   - Update LAN IP addresses in compose files if your server IP is not `192.168.2.7`
   - Check timezone settings (currently set to `Europe/Amsterdam`)
   - Verify paths and permissions

4. **Create required directories** (for media stack):
   ```bash
   # These should already exist based on your structure
   mkdir -p stacks/media/{downloads,media/movies,media/tv}
   ```

### Starting Services

#### Start All Services

```bash
# Start core infrastructure first
docker compose -f npm/docker-compose.yml up -d
docker compose -f portainer/docker-compose.yml up -d
docker compose -f postgres/docker-compose.yml up -d
docker compose -f mariadb/docker-compose.yml up -d
docker compose -f wud/docker-compose.yml up -d

# Start application stacks
docker compose -f stacks/media/docker-compose.yml up -d
docker compose -f stacks/homeassistant/docker-compose.yml up -d
docker compose -f stacks/matomo/docker-compose.yml up -d
docker compose -f stacks/whoami/docker-compose.yml up -d
```

#### Start Individual Stacks

```bash
# Media stack only
cd stacks/media
docker compose up -d

# Home Assistant only
cd stacks/homeassistant
docker compose up -d

# Core infrastructure
cd npm
docker compose up -d
```

### First-Time Configuration

#### 1. Nginx Proxy Manager Setup
```bash
# Access at http://192.168.2.7:81
# Default credentials:
#   Email: admin@example.com
#   Password: changeme
# Change these immediately after first login
```

#### 2. Portainer Setup
```bash
# Access at https://192.168.2.7:9443
# Create admin user on first access
```

#### 3. Media Stack Configuration

The media stack services need to be configured in this order:

1. **qBittorrent** (`http://your-server:8080`)
   - Default username: `admin`
   - Password is shown in logs on first run:
     ```bash
     docker logs qbittorrent 2>&1 | grep "temporary password"
     ```

2. **Prowlarr** (`http://your-server:9696`)
   - Add FlareSolverr: Settings → Indexers → FlareSolverr
     - Tags: `flaresolverr`
     - Host: `http://flaresolverr:8191`
   - Add indexers with appropriate tags
   - Add Sonarr and Radarr as Apps

3. **Sonarr** (`http://your-server:8989`)
   - Add download client (qBittorrent)
   - Configure root folder: `/tv`
   - Connect to Prowlarr

4. **Radarr** (`http://your-server:7878`)
   - Add download client (qBittorrent)
   - Configure root folder: `/movies`
   - Connect to Prowlarr

5. **Bazarr** (`http://your-server:6767`)
   - Add Sonarr: Settings → Sonarr
   - Add Radarr: Settings → Radarr
   - Configure subtitle providers

#### 4. Home Assistant Setup
```bash
# Access at http://your-server:8123
# Follow the onboarding wizard on first access
```

#### 5. MariaDB Setup (for Matomo and other services)

The shared MariaDB instance requires creating databases/users for each service:

```bash
# Start MariaDB first
cd /home/projects/homelab/mariadb
docker compose up -d

# Wait for it to be healthy
docker compose ps

# Create Matomo database and user
docker exec -it mariadb mariadb -u root -p -e "
CREATE DATABASE IF NOT EXISTS matomo;
CREATE USER IF NOT EXISTS 'matomo'@'%' IDENTIFIED BY 'matomo_secure_password';
GRANT ALL PRIVILEGES ON matomo.* TO 'matomo'@'%';
FLUSH PRIVILEGES;"
# Enter the root password when prompted: fill_in_something
```

**Adding new services to MariaDB:**
```bash
# Template for adding a new service
docker exec -it mariadb mariadb -u root -p -e "
CREATE DATABASE <service_name>;
CREATE USER '<service_user>'@'%' IDENTIFIED BY '<secure_password>';
GRANT ALL PRIVILEGES ON <service_name>.* TO '<service_user>'@'%';
FLUSH PRIVILEGES;"
```

#### 6. Matomo Setup
```bash
# Start Matomo (after MariaDB is running and database is created)
cd /home/projects/homelab/stacks/matomo
docker compose up -d

# Access at http://your-server:8090
# The database connection is pre-configured via environment variables
# Follow the web-based setup wizard
```

#### 7. WUD (What's Up Docker) Setup
```bash
# Start WUD
cd /home/projects/homelab/wud
docker compose up -d

# Access at http://192.168.2.7:3069
# WUD will automatically detect all running containers
```

**WUD Configuration Options:**

WUD can be configured via environment variables in the docker-compose file:

```yaml
# Check for updates every 6 hours instead of daily
WUD_WATCHER_LOCAL_CRON=0 */6 * * *

# Only watch containers with specific label
WUD_WATCHER_LOCAL_WATCHBYDEFAULT=false
# Then add label to containers you want to watch:
# labels:
#   - wud.watch=true

# Enable Discord notifications
WUD_TRIGGER_DISCORD_MYNOTIFIER_URL=https://discord.com/api/webhooks/xxx/yyy
WUD_TRIGGER_DISCORD_MYNOTIFIER_THRESHOLD=all
```

**Using WUD to monitor updates:**

1. Access the WUD dashboard at `http://192.168.2.7:3069`
2. View all containers and their update status
3. Containers with available updates will be highlighted
4. Use the information to decide when to run `update-homelab.sh`

## 🔧 Managing Services

### View Running Containers

```bash
# All containers
docker ps

# Containers in a specific stack
cd stacks/media
docker compose ps
```

### View Logs

```bash
# View logs for all services in a stack
cd stacks/media
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Logs for a specific service
docker compose logs sonarr

# Last 100 lines
docker compose logs --tail=100 sonarr

# Individual container logs
docker logs qbittorrent
docker logs -f radarr
```

### Stop Services

```bash
# Stop a specific stack
cd stacks/media
docker compose stop

# Stop a specific service
docker compose stop sonarr

# Stop and remove containers (preserves data)
docker compose down

# Stop all containers
docker stop $(docker ps -q)
```

### Restart Services

```bash
# Restart entire stack
cd stacks/media
docker compose restart

# Restart specific service
docker compose restart sonarr

# Restart individual container
docker restart qbittorrent
```

### Remove Services

```bash
# Remove containers but keep volumes (data preserved)
cd stacks/media
docker compose down

# Remove containers AND volumes (⚠️ DELETES DATA!)
docker compose down -v

# Remove containers and unused images
docker compose down --rmi all
```

## 🔄 Updating Services

### Method 1: Update All Services in a Stack

This is the recommended approach for updating multiple services:

```bash
# Navigate to the stack directory
cd stacks/media

# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Remove old images (optional cleanup)
docker image prune -f
```

### Method 2: Update a Specific Service

```bash
# Navigate to the stack directory
cd stacks/media

# Pull latest image for specific service
docker compose pull sonarr

# Recreate only that service
docker compose up -d sonarr

# Clean up old images
docker image prune -f
```

### Method 3: Update Individual Container

```bash
# Pull the latest image
docker pull lscr.io/linuxserver/sonarr:latest

# Stop and remove the container
docker stop sonarr
docker rm sonarr

# Recreate from compose file
cd stacks/media
docker compose up -d sonarr
```

### Complete Update Workflow

Update all services in your homelab:

```bash
#!/bin/bash
# Save this as update-homelab.sh

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
```

Make it executable and run:
```bash
chmod +x update-homelab.sh
./update-homelab.sh
```

### Monitoring Updates with WUD

This homelab uses **WUD (What's Up Docker)** to monitor for available container updates:

- **Dashboard**: Access at `http://192.168.2.7:3069`
- **Features**: Shows all containers with available updates highlighted
- **Schedule**: Checks for updates daily at midnight (configurable)

WUD provides visibility into available updates without automatically applying them, giving you control over when to update. When WUD shows updates are available, run the update script:

```bash
cd /home/projects/homelab
./update-homelab.sh
```

**Optional: Add notifications** to be alerted when updates are available:

```yaml
# Add to wud/docker-compose.yml environment section:

# Discord notifications
- WUD_TRIGGER_DISCORD_HOMELAB_URL=https://discord.com/api/webhooks/xxx/yyy

# Email notifications (requires SMTP)
- WUD_TRIGGER_SMTP_GMAIL_HOST=smtp.gmail.com
- WUD_TRIGGER_SMTP_GMAIL_PORT=587
- WUD_TRIGGER_SMTP_GMAIL_USER=your@gmail.com
- WUD_TRIGGER_SMTP_GMAIL_PASS=app-password
- WUD_TRIGGER_SMTP_GMAIL_FROM=your@gmail.com
- WUD_TRIGGER_SMTP_GMAIL_TO=your@gmail.com
```

### Update Best Practices

1. **Always backup before major updates**:
   ```bash
   # Backup volumes
   docker run --rm -v media_prowlarr_config:/data -v $(pwd):/backup \
     ubuntu tar czf /backup/prowlarr-backup-$(date +%Y%m%d).tar.gz /data
   ```

2. **Check release notes**: Review changelogs for breaking changes
   - Home Assistant: https://www.home-assistant.io/blog/
   - LinuxServer.io images: https://fleet.linuxserver.io/

3. **Update one stack at a time**: Easier to troubleshoot issues

4. **Monitor logs after updates**:
   ```bash
   docker compose logs -f --tail=50
   ```

5. **Test functionality**: Verify services work after updates

### Rollback to Previous Version

If an update causes issues:

```bash
# Stop the service
docker compose stop sonarr

# Pull specific version
docker pull lscr.io/linuxserver/sonarr:3.0.10

# Update compose file temporarily or use image SHA
docker compose up -d sonarr
```

Or restore from backup:
```bash
# Stop service
docker compose down sonarr

# Restore config volume
docker run --rm -v sonarr_config:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/sonarr-backup-20250115.tar.gz -C /

# Start service
docker compose up -d sonarr
```

## 🔍 Troubleshooting

### Check Service Health

```bash
# View container status
docker ps -a

# Check specific container health
docker inspect sonarr | grep -A 10 Health

# View resource usage
docker stats
```

### Common Issues

#### Container won't start
```bash
# Check logs for errors
docker logs container-name

# Verify network exists
docker network ls

# Check port conflicts
sudo netstat -tulpn | grep :8989
```

#### Permission issues (media stack)
```bash
# Fix ownership (PUID/PGID = 1000)
sudo chown -R 1000:1000 stacks/media/downloads
sudo chown -R 1000:1000 stacks/media/media
```

#### Network connectivity issues
```bash
# Verify networks exist
docker network inspect proxy
docker network inspect media

# Recreate network
docker network rm media
docker compose -f stacks/media/docker-compose.yml up -d
```

#### Home Assistant USB device not found
```bash
# List USB devices
ls -la /dev/ttyUSB*

# Add user to dialout group
sudo usermod -aG dialout $USER

# Restart container
docker restart homeassistant
```

### Reset a Service

```bash
# Complete reset (deletes all data)
cd stacks/media
docker compose down
rm -rf ./sonarr/config/*
docker compose up -d sonarr
```

## 💾 Backup and Restore

### Backup Configuration

#### Backup All Configs

```bash
#!/bin/bash
# backup-configs.sh

HOMELAB_DIR="/home/projects/homelab"
BACKUP_DIR="/backup/homelab-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup each stack's config
cp -r "$HOMELAB_DIR/npm/data" "$BACKUP_DIR/npm-data"
cp -r "$HOMELAB_DIR/portainer/data" "$BACKUP_DIR/portainer-data"
cp -r "$HOMELAB_DIR/mariadb/data" "$BACKUP_DIR/mariadb-data"
cp -r "$HOMELAB_DIR/stacks/media/sonarr/config" "$BACKUP_DIR/sonarr-config"
cp -r "$HOMELAB_DIR/stacks/media/radarr/config" "$BACKUP_DIR/radarr-config"
cp -r "$HOMELAB_DIR/stacks/media/prowlarr/config" "$BACKUP_DIR/prowlarr-config"
cp -r "$HOMELAB_DIR/stacks/media/bazarr/config" "$BACKUP_DIR/bazarr-config"
cp -r "$HOMELAB_DIR/stacks/media/qbittorrent/config" "$BACKUP_DIR/qbittorrent-config"
cp -r "$HOMELAB_DIR/stacks/homeassistant/config" "$BACKUP_DIR/homeassistant-config"
cp -r "$HOMELAB_DIR/stacks/matomo/data" "$BACKUP_DIR/matomo-data"

# Backup compose files
cp -r "$HOMELAB_DIR"/*.yml "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$HOMELAB_DIR/stacks" "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

#### Backup PostgreSQL Database

```bash
# Backup database
docker exec postgres pg_dumpall -U username > postgres-backup-$(date +%Y%m%d).sql

# Or backup specific database
docker exec postgres pg_dump -U username postgres > postgres-db-backup-$(date +%Y%m%d).sql
```

#### Backup Docker Volumes

```bash
# List volumes
docker volume ls

# Backup a volume
docker run --rm -v postgres-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/postgres-data-$(date +%Y%m%d).tar.gz /data
```

### Restore Configuration

#### Restore from backup

```bash
# Stop services
cd stacks/media
docker compose down

# Restore configs
cp -r /backup/homelab-20250115/sonarr-config/* ./sonarr/config/

# Start services
docker compose up -d
```

#### Restore PostgreSQL Database

```bash
# Restore all databases
docker exec -i postgres psql -U username < postgres-backup-20250115.sql

# Restore specific database
docker exec -i postgres psql -U username postgres < postgres-db-backup-20250115.sql
```

## 📊 Monitoring

### Resource Usage

```bash
# Real-time stats
docker stats

# Disk usage
docker system df

# Detailed disk usage
docker system df -v
```

### Log Rotation

Configure log rotation to prevent disk space issues:

```bash
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker daemon:
```bash
sudo systemctl restart docker
```

## 🔒 Security Considerations

1. **Change default passwords**:
   - PostgreSQL password in `postgres/docker-compose.yml`
   - MariaDB root password in `mariadb/docker-compose.yml`
   - Matomo database password in `stacks/matomo/docker-compose.yml`
   - Nginx Proxy Manager admin credentials
   - qBittorrent web UI password

2. **Firewall configuration**:
   ```bash
   # Allow only necessary ports
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

3. **Use SSL/TLS**: Configure certificates in Nginx Proxy Manager

4. **Regular updates**: Keep images updated for security patches

5. **Backup regularly**: Automate backups of configurations and data

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [LinuxServer.io Documentation](https://docs.linuxserver.io/)
- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [Nginx Proxy Manager Documentation](https://nginxproxymanager.com/guide/)
- [TRaSH Guides](https://trash-guides.info/) - Excellent guides for *arr services

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements to this homelab setup.

## 📝 License

This configuration is provided as-is for personal use.

---

**Last Updated**: December 2, 2025
