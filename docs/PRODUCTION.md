# Production checklist (KMC Alumni Connect)

## Frontend (KMC-Frontend)

```bash
# Required in deploy env / .env (never localhost in real prod):
ENV=production
API_BASE_URL=https://YOUR-API-HOST
API_PREFIX=/api/v1
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key

docker compose up -d --build
```

- App: host port **8080** (nginx)
- Local coding with live reload: `docker compose -f docker-compose.dev.yml up --build`
- Default API fallback in code is `http://localhost:8001` for local only

## Backend (KMC-Backend)

```bash
# Required in .env on the server:
ENV=production
CORS_ORIGIN=https://YOUR-FRONTEND-HOST
JWT_SECRET=long-random-secret
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...

docker compose -f docker-compose.prod.yml up -d --build
# or: docker compose up -d --build  (default compose = API only on 8000)
```

- Do **not** use `docker-compose.dev.yml` in production (reload + migration watcher)

## Database (Supabase)

1. Open Supabase → **Connect** → **Connection pooling** → copy **URI**
2. Put in backend `.env` (local auto-migrate only):

```env
SUPABASE_DB_POOLER_URL=postgresql://postgres.YOUR_REF:PASSWORD@aws-X-REGION.pooler.supabase.com:5432/postgres
```

3. Apply pending SQL once (production):

```bash
cd KMC-Backend
python scripts/auto_apply_migrations.py
# or paste docs/migration-*.sql in Supabase SQL Editor
```

Critical recent migration: `docs/migration-027-ec-org-posts.sql` (`joint_secretary`, `editor`).

## Go-live smoke test

- [ ] `GET https://YOUR-API/health` → `{"status":"ok"}`
- [ ] FE loads and login works
- [ ] Admin → Members role change works
- [ ] Connect / Alumni Chat loads
- [ ] Events / Gallery / Payments smoke paths OK
