# Production deploy (FE + BE + DB) — Docker

**Live hosts:** https://kmcalumni.net · API https://api.kmcalumni.net  

This is **production only**. Do **not** use `docker-compose.dev.yml`, LAN IPs (`200.141…`), or local Postgres (`5433`) here.

Deploy order is always:

```
1) DB migration  →  2) Backend Docker  →  3) Frontend Docker
```

Frontend Docker **never** updates Postgres. Backend Docker **does not** auto-run SQL migrations — you apply them once on production DB.

---

## 1) Database (production Postgres)

On the **production** server (or via production pgAdmin), apply pending migrations **before** new backend/frontend that need those columns.

### Current required migration (registration docs / MC number)

File (in **KMC-Backend**): `docs/migration-032-council-certificate.sql`

**Option A — Docker exec (prod Postgres container):**

```powershell
cd C:\Users\user\Downloads\KMC-Backend
git checkout main
git pull origin main

# PowerShell (Windows) — do NOT use bash-style < redirection
Get-Content docs\migration-032-council-certificate.sql -Raw | docker exec -i kmc-prod-postgres psql -U kmc -d kmc
```

```bash
# Linux / macOS / Git Bash
cd /path/to/KMC-Backend
git pull origin main
docker exec -i kmc-prod-postgres psql -U kmc -d kmc < docs/migration-032-council-certificate.sql
```

**Option B — pgAdmin (production server only):**

1. Connect to **production** Postgres (`kmc-prod-postgres` / your cloud DB)  
2. Open Query Tool → paste / open `migration-032-council-certificate.sql`  
3. Execute once (safe: uses `ADD COLUMN IF NOT EXISTS`)

### Verify columns exist

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'alumni_profiles'
  AND column_name IN (
    'council_certificate_url',
    'mcr_certificate_url',
    'kmc_ug_certificate_url',
    'pg_certificate_url',
    'medical_council_number'
  );
```

Expect **5 rows**. If already applied earlier, skip — do not worry about re-running.

---

## 2) Backend (KMC-Backend) — production Docker

```bash
cd /path/to/KMC-Backend
git checkout main
git pull origin main

# Ensure .env.production has production values (not local):
#   ENV=production
#   PUBLIC_API_BASE_URL=https://api.kmcalumni.net
#   CORS_ORIGIN=https://kmcalumni.net
#   RAZORPAY live keys, JWT_SECRET, POSTGRES_PASSWORD, etc.

docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
```

### Smoke

```bash
curl -sS https://api.kmcalumni.net/health
# or on server: curl -sS http://127.0.0.1/health
docker ps --filter name=kmc-prod-
```

Containers: `kmc-prod-postgres`, `kmc-prod-api`, `kmc-prod-nginx` (optional `kmc-prod-pgadmin`).

Full first-time VPS setup: `KMC-Backend/docs/PRODUCTION.md`.

---

## 3) Frontend (KMC-Frontend) — production Docker

```bash
cd /path/to/KMC-Frontend
git checkout main
git pull origin main

docker compose up -d --build
```

Defaults (already production-safe):

| Env | Default |
| --- | --- |
| `ENV` | `production` |
| `API_BASE_URL` | `https://api.kmcalumni.net` |
| `API_PREFIX` | `/api/v1` |
| `RAZORPAY_KEY_ID` | live public key |

Override only if needed:

```bash
ENV=production \
API_BASE_URL=https://api.kmcalumni.net \
RAZORPAY_KEY_ID=rzp_live_YOUR_KEY \
docker compose up -d --build
```

### Smoke

1. Open https://kmcalumni.net (hard refresh)  
2. Check https://kmcalumni.net/env-config.js → API URL + `rzp_live_...`  
3. Login (email / MC number)  
4. Membership pay — no “Demo” badge  
5. Join Network docs upload works (needs migration-032 + BE)

App port on host: **8080** (map behind Cloudflare / reverse proxy as you already do).

---

## One-shot checklist (after merge to `main`)

- [ ] **DB:** run `migration-032` on **production** Postgres (if not already)  
- [ ] **BE:** `git pull` + `docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build`  
- [ ] **FE:** `git pull` + `docker compose up -d --build`  
- [ ] Health + login + pay + registration docs smoke tests  

---

## Do not use for production

| Wrong (local) | Right (production) |
| --- | --- |
| `docker-compose.dev.yml` | FE: `docker compose.yml` / BE: `docker-compose.prod.yml` |
| `http://200.141.2.90:8001` | `https://api.kmcalumni.net` |
| Local Postgres `:5433` / `kmc-postgres` | `kmc-prod-postgres` or cloud `DATABASE_URL` |
| `rzp_test_...` | `rzp_live_...` |

---

## Local development (separate)

See `docs/hybrid-local-dev.md` and `KMC-Backend/docs/PRODUCTION.md` § Local. Never mix local compose files with the production stack containers (`kmc-prod-*`).
