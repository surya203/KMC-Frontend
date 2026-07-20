# Production checklist (KMC Alumni Connect)

## What is already done (local)

- [x] Supabase → local PostgreSQL + pgAdmin
- [x] API uses `DATABASE_URL` (no Supabase required)
- [x] Storage files local + `/media/...`
- [x] Production Docker compose + backup/restore scripts in **KMC-Backend**

## What you still need for a live production site

1. A **VPS or cloud Postgres** (DigitalOcean / AWS / Neon / Railway / etc.)
2. Deploy backend with `docker-compose.prod.yml` + `.env.production`
3. Restore DB dump + `storage_data`
4. Deploy frontend with `API_BASE_URL=https://YOUR-API`
5. HTTPS (Cloudflare / Caddy / Let’s Encrypt)

Full steps: `KMC-Backend/docs/PRODUCTION.md`

## Frontend (KMC-Frontend)

```bash
ENV=production
API_BASE_URL=https://YOUR-API-HOST
API_PREFIX=/api/v1

docker compose up -d --build
```

- App: host port **8080** (nginx)
- Local coding: `docker compose -f docker-compose.dev.yml up --build`

## Backend (KMC-Backend)

```bash
cp .env.production.example .env.production
# edit secrets + PUBLIC_API_BASE_URL + CORS_ORIGIN

docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
```

## Smoke checks (production)

- [ ] `GET https://YOUR-API/health` → OK
- [ ] Login works against production DB
- [ ] Members / events / gallery
- [ ] Upload lands in production storage volume
- [ ] Nightly `backup_prod_db.ps1` (or equivalent) scheduled
