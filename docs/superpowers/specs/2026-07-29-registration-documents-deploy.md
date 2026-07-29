# Registration documents — production deploy

Mandatory Join Network uploads (MCR / KMC UG / PG) + MC number.  
**Production only** — not local LAN / `docker-compose.dev.yml`.

## Order

| Step | Where | Action |
|------|--------|--------|
| 1 **DB** | Production Postgres (`kmc-prod-postgres`) | `docs/migration-032-council-certificate.sql` |
| 2 **BE** | KMC-Backend `main` | `docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build` |
| 3 **FE** | KMC-Frontend `main` | `docker compose up -d --build` |

Full copy-paste: `KMC-Frontend/docs/PRODUCTION.md` and `KMC-Backend/docs/PRODUCTION.md`.

## DB command (PowerShell)

```powershell
cd C:\Users\user\Downloads\KMC-Backend
git pull origin main
Get-Content docs\migration-032-council-certificate.sql -Raw | docker exec -i kmc-prod-postgres psql -U kmc -d kmc
```

## Confirm after deploy

- Join Network → Details shows 3 required documents  
- MC number login works  
- `https://api.kmcalumni.net/health` OK  
- `https://kmcalumni.net/env-config.js` → `API_BASE_URL=https://api.kmcalumni.net`
