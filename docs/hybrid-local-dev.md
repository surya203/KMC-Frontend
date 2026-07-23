# Local development with Docker live reload

## Start

**Postgres + pgAdmin (once):**

```powershell
cd C:\Users\user\Downloads\KMC-Backend
docker compose -f docker-compose.pgsql.yml up -d
```

**Backend:**

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
| App | http://200.141.2.90:8080 |
| API | http://200.141.2.90:8001/health |
| pgAdmin | http://200.141.2.90:5050 |

## What auto-updates

| Change | Auto? | Notes |
| --- | --- | --- |
| FE (`lib/`) | **Yes** | Refresh http://200.141.2.90:8080 |
| BE (`app/`) | **Yes** | uvicorn reload |
| DB (`docs/migration-*.sql`) | Manual | Apply via psql / pgAdmin against local Postgres |

### Database (local Postgres + pgAdmin)

```powershell
cd C:\Users\user\Downloads\KMC-Backend
docker compose -f docker-compose.pgsql.yml up -d
# Optional one-time copy from old Supabase:
powershell -File scripts\dump_supabase_to_local.ps1
```

In `KMC-Backend/.env`:

```env
DATABASE_URL=postgresql://kmc:kmc@200.141.2.90:5433/kmc
PUBLIC_API_BASE_URL=http://200.141.2.90:8001
LOCAL_STORAGE_ROOT=./storage_data
```

- Postgres: `200.141.2.90:5433` (`kmc` / `kmc` / `kmc`)
- pgAdmin: http://200.141.2.90:5050 — details in `KMC-Backend/docs/migrate-to-pgsql-pgadmin.md`
- Full cutover guide: `KMC-Backend/docs/migrate-to-pgsql-pgadmin.md`

### Legacy remote migrator

If you still point `SUPABASE_DB_POOLER_URL` at a remote DB:

```powershell
cd C:\Users\user\Downloads\KMC-Backend
powershell -File scripts/start_db_migrate_host.ps1
```
