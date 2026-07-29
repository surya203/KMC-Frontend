# Registration documents (MCR / KMC UG / PG)

Mandatory Join Network uploads. Changes live on **Suresh** branches until merge → main → sir deploy.

## What was added

| Layer | Change |
|-------|--------|
| **FE** | Details step: dropdown + upload for 3 required docs |
| **BE** | `POST /api/v1/auth/register/draft/{id}/registration-document` (`document_type` = `mcr` \| `kmc_ug` \| `pg`) |
| **DB** | `docs/migration-032-council-certificate.sql` → columns on `alumni_profiles` |
| **Integration** | Checkout rejects drafts missing any of the 3 paths; profile stores URLs after payment |

## Local test (do not use prod Docker API)

- Postgres local: `kmc-postgres` on **5433** (compose `docker-compose.pgsql.yml`)
- **Leave alone:** `kmc-prod-*` containers (production stack)
- API with this branch code: local uvicorn on **8001**
- FE: `flutter run -d chrome --web-port=8085 --dart-define=API_BASE_URL=http://localhost:8001`

## Production deploy (sir)

1. Run SQL in pgAdmin (production DB): `docs/migration-032-council-certificate.sql`
2. Deploy **KMC-Backend** `suresh` → `main`
3. Deploy **KMC-Frontend** `Suresh` → `main`
4. Confirm Join Network → Details shows 3 required documents
