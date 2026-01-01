# Outline Wiki

A modern team knowledge base and wiki. This setup uses the existing Postgres container and Nginx Proxy Manager (NPM) for reverse proxying.

## Prerequisites

- Existing `postgres` container running on the `proxy` network
- Existing `npm` (Nginx Proxy Manager) container
- The `proxy` Docker network must exist

## Setup Instructions

### 1. Create the Outline database user and schema

Connect to your existing Postgres container and run these SQL commands:

```bash
# Connect to postgres container
docker exec -it postgres psql -U postgres
```

Then run the following SQL:

```sql
-- Create the outline user with a secure password
CREATE USER outline WITH PASSWORD 'YOUR_SECURE_PASSWORD_HERE';

-- Create the outline database
CREATE DATABASE outline OWNER outline;

-- Connect to the outline database
\c outline

-- Grant all privileges to the outline user
GRANT ALL PRIVILEGES ON DATABASE outline TO outline;
GRANT ALL PRIVILEGES ON SCHEMA public TO outline;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO outline;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO outline;

-- Exit psql
\q
```

### 2. Configure Environment Variables

```bash
# Copy the example environment file
cp docker.env.example docker.env

# Generate the required secrets
echo "SECRET_KEY=$(openssl rand -hex 32)"
echo "UTILS_SECRET=$(openssl rand -hex 32)"
```

Edit `docker.env` and fill in:
- `SECRET_KEY` and `UTILS_SECRET` with the generated values
- `URL` with your Outline URL (e.g., `https://outline.yourdomain.com`)
- `DATABASE_URL` with the password you set for the outline user
- Configure at least ONE authentication provider (OIDC, Google, Slack, etc.)

> ⚠️ **Important**: Outline does NOT support email/password authentication. You MUST configure an SSO provider!

### 3. Start Outline

```bash
docker compose up -d
```

Check the logs for any errors:

```bash
docker compose logs -f outline
```

### 4. Configure Nginx Proxy Manager

1. Open your NPM admin panel (usually at `http://YOUR_SERVER_IP:81`)
2. Add a new Proxy Host:
   - **Domain Names**: `outline.yourdomain.com`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: `outline`
   - **Forward Port**: `3000`
   - **Websockets Support**: ✅ Enabled (important for real-time collaboration!)
   - **Block Common Exploits**: ✅ Enabled
3. SSL Tab:
   - **SSL Certificate**: Request a new SSL certificate or use existing
   - **Force SSL**: ✅ Enabled
   - **HTTP/2 Support**: ✅ Enabled
4. Advanced Tab (optional, for larger file uploads):
   ```nginx
   client_max_body_size 250M;
   proxy_read_timeout 300;
   proxy_connect_timeout 300;
   proxy_send_timeout 300;
   ```

### 5. Configure Authentication

Outline requires SSO authentication. Here are the most common options:

#### Option A: Generic OIDC (Authelia, Authentik, Keycloak)

If using **Authentik**, follow: https://docs.goauthentik.io/integrations/services/outline/

If using **Authelia**, follow: https://www.authelia.com/integration/openid-connect/outline/

Example configuration in `docker.env`:
```env
OIDC_ISSUER_URL=https://auth.yourdomain.com
OIDC_CLIENT_ID=outline
OIDC_CLIENT_SECRET=your_client_secret_here
OIDC_DISPLAY_NAME=Login with SSO
OIDC_SCOPES=openid profile email
```

#### Option B: Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create OAuth 2.0 credentials
3. Set the authorized redirect URI to: `https://outline.yourdomain.com/auth/google.callback`
4. Add to `docker.env`:
   ```env
   GOOGLE_CLIENT_ID=your_client_id
   GOOGLE_CLIENT_SECRET=your_client_secret
   ```

#### Option C: Slack OAuth

1. Create a Slack app at https://api.slack.com/apps
2. Set the redirect URL to: `https://outline.yourdomain.com/auth/slack.callback`
3. Add to `docker.env`:
   ```env
   SLACK_CLIENT_ID=your_client_id
   SLACK_CLIENT_SECRET=your_client_secret
   ```

## Maintenance

### Backup

The important data to backup:
- Postgres database (the `outline` database)
- Storage volume: `outline_storage-data`

```bash
# Backup the database
docker exec postgres pg_dump -U outline outline > outline_backup_$(date +%Y%m%d).sql

# Backup the storage volume
docker run --rm -v outline_storage-data:/data -v $(pwd):/backup alpine tar czf /backup/outline_storage_$(date +%Y%m%d).tar.gz -C /data .
```

### Update

```bash
# Pull the latest image
docker compose pull

# Recreate the container (migrations run automatically)
docker compose up -d
```

## Troubleshooting

### Check logs
```bash
docker compose logs -f outline
docker compose logs -f redis
```

### Database connection issues
Make sure the Postgres container is on the `proxy` network:
```bash
docker network inspect proxy | grep postgres
```

### Redis connection issues
```bash
docker exec outline-redis redis-cli ping
# Should return: PONG
```

### OIDC authentication issues
- Verify your OIDC provider's callback URL is set correctly
- Check that the client ID and secret are correct
- For self-signed certificates, you may need to set `NODE_TLS_REJECT_UNAUTHORIZED=0`

## Resources

- [Outline Documentation](https://docs.getoutline.com/)
- [Outline GitHub](https://github.com/outline/outline)
- [Authentication Options](https://docs.getoutline.com/s/hosting/doc/authentication-7ViKRmRY5o)
