# Plausible Analytics Setup

This directory contains the Plausible Analytics Community Edition setup for your homelab.

## Key Modifications

- **Uses existing PostgreSQL**: Instead of running a separate PostgreSQL container, this configuration uses your homelab's existing PostgreSQL instance running at `postgres:5432` on the `proxy` network.
- **Dedicated ClickHouse**: Plausible requires ClickHouse for events storage, which is included as a separate service.
- **Network**: Connected to your `proxy` network for integration with other services.

## Database Setup

Before starting Plausible, you need to create a dedicated user and schema in your PostgreSQL instance:

```bash
# Connect to your postgres container
docker exec -it postgres psql -U some_user -d postgres

# Create the plausible user (replace 'your_secure_password' with a strong password)
CREATE USER plausible WITH PASSWORD 'your_secure_password';

# Grant CREATE privilege on the database (needed for extensions)
GRANT CREATE ON DATABASE postgres TO plausible;

# Grant usage on public schema (where extensions are installed)
GRANT USAGE ON SCHEMA public TO plausible;
GRANT CREATE ON SCHEMA public TO plausible;

# Create the plausible schema
CREATE SCHEMA plausible AUTHORIZATION plausible;

# Grant permissions to the plausible user
GRANT ALL ON SCHEMA plausible TO plausible;
GRANT ALL ON ALL TABLES IN SCHEMA plausible TO plausible;
ALTER DEFAULT PRIVILEGES IN SCHEMA plausible GRANT ALL ON TABLES TO plausible;

# Create required PostgreSQL extension (Plausible needs citext)
CREATE EXTENSION IF NOT EXISTS citext;

# Exit psql
\q
```

## Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Generate a secret key:
   ```bash
   openssl rand -base64 48
   ```

3. Edit `.env` and set:
   - `BASE_URL`: The URL where Plausible will be accessible (e.g., `https://analytics.yourdomain.com`)
   - `SECRET_KEY_BASE`: The generated secret key from step 2
   - Any other optional settings you need

## Starting Plausible

```bash
docker compose up -d
```

## Database Connection Details

The `DATABASE_URL` is configured as:
```
postgres://plausible:your_secure_password@postgres:5432/postgres?options=--search_path%3Dplausible
```

This connects to the `postgres` database using the `plausible` user and the `plausible` schema via the `search_path` parameter.

**Important**: Update the password in [docker-compose.yml](docker-compose.yml) to match the password you set when creating the `plausible` user.

## Access

Once running, access Plausible at your configured `BASE_URL` and create your first user account.

## Notes

- The first time you start Plausible, it will automatically create the necessary tables in the `plausible` schema.
- ClickHouse data is stored in Docker volumes for persistence.
- Consider setting `DISABLE_REGISTRATION=true` in your `.env` file after creating your admin account.
