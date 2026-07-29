# Production update — Windows PowerShell (copy/paste)

**Do NOT type `/path/to/...`.** Use these real folders.

Your machine paths:
- Backend: `C:\Users\user\Downloads\KMC-Backend`
- Frontend: `C:\Users\user\Downloads\KMC-Frontend`

---

## Status after today’s deploy

| Step | Status |
|------|--------|
| 1. DB migration-032 | DONE |
| 2. Backend API/nginx recreate (`kmcprod`) | DONE — health OK on port **8081** |
| 3. Frontend Docker rebuild | DONE — `http://127.0.0.1:8080` + prod `env-config.js` |

Check:
- FE: http://127.0.0.1:8080  
- API local: http://127.0.0.1:8081/health → `{"status":"ok"}`  
- Live site: https://kmcalumni.net (hard refresh)  
- Live API: https://api.kmcalumni.net/health  

---

## Next time (full update after merge)

### 1) DB
```powershell
cd C:\Users\user\Downloads\KMC-Backend
git pull origin main
Get-Content docs\migration-032-council-certificate.sql -Raw | docker exec -i kmc-prod-postgres psql -U kmc -d kmc
```

### 2) Backend (use project name `kmcprod`)
```powershell
cd C:\Users\user\Downloads\KMC-Backend
git pull origin main
docker compose -p kmcprod -f docker-compose.prod.yml --env-file .env.production up -d --build --no-deps api
docker compose -p kmcprod -f docker-compose.prod.yml --env-file .env.production up -d --no-deps nginx
```

### 3) Frontend
```powershell
cd C:\Users\user\Downloads\KMC-Frontend
git checkout main
git pull origin main
docker compose up -d --build
```

If port 8080 busy:
```powershell
docker stop kmc-frontend-prod
docker rm kmc-frontend-prod
docker compose up -d --force-recreate
```

### 4) Quick checks
```powershell
Invoke-WebRequest http://127.0.0.1:8081/health -UseBasicParsing
Invoke-WebRequest http://127.0.0.1:8080/env-config.js -UseBasicParsing
docker ps --filter name=kmc
```

---

## Remember

- PowerShell: never use `< file.sql` — use `Get-Content ... | docker exec -i ...`
- Never type `/path/to/...`
- FE Docker does **not** update DB
- Backend project name must be **`kmcprod`** or container names conflict
