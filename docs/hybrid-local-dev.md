# Local development with Docker live reload

## Start

**Backend + DB migrator:**

```powershell
cd C:\Users\user\Downloads\KMC-Backend
docker compose -f docker-compose.dev.yml up --build
```

**Frontend:**

```powershell
cd C:\Users\user\Downloads\KMC-Frontend
docker compose -f docker-compose.dev.yml up --build
```

| Open | URL |
| --- | --- |
| App | http://localhost:8080 |
| API | http://localhost:8001/health |

## What auto-updates

| Change | Auto? | Notes |
| --- | --- | --- |
| FE (`lib/`) | **Yes** | Refresh http://localhost:8080 |
| BE (`app/`) | **Yes** | uvicorn reload |
| DB (`docs/migration-*.sql`) | **Yes*** | `kmc-db-migrate` applies SQL |

### DB setup (one-time — required for auto-migrate)

Supabase direct DB host is often **IPv6-only**. Docker Desktop usually cannot reach it.

1. Open Supabase → **Project Settings → Database → Connect**
2. Choose **Connection pooling** (URI)
3. Copy the URI into `KMC-Backend/.env`:

```env
SUPABASE_DB_POOLER_URL=postgresql://postgres.YOUR_REF:YOUR_PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres
```

4. Restart:

```powershell
docker restart kmc-db-migrate
docker logs kmc-db-migrate --tail 30
```

You should see: `connected via ...pooler...` then `startup done`.

After that, saving a new `docs/migration-028-....sql` applies automatically within ~5 seconds.

### If Docker migrator still cannot connect

Run on the Windows host instead:

```powershell
cd C:\Users\user\Downloads\KMC-Backend
powershell -File scripts/start_db_migrate_host.ps1
```
