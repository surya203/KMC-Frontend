# Phase 4 — UAT sign-off checklist

Use this checklist before production launch. Store signed PDF in `/docs` per QA process.

## Public site (FE)

- [ ] Home loads stats from `/api/v1/cms/stats`
- [ ] About page loads from `/api/v1/cms/about`
- [ ] Events list + detail + register (signed-in member)
- [ ] Gallery albums + lightbox + pagination
- [ ] Directory search + profile detail
- [ ] Membership wizard (plan → verify → pay → complete)
- [ ] Sign-in redirects to member dashboard
- [ ] Footer and nav work at **375px** width

## Member dashboard (FE)

- [ ] Dashboard analytics cards load live data
- [ ] Profile edit + photo upload persist
- [ ] Membership + payments history screens
- [ ] Announcements list + expand detail
- [ ] Events register from dashboard

## Staff console (FE + BE)

- [ ] Admin login redirects to `/admin`
- [ ] Verifier/staff login redirects to `/admin/verifications`
- [ ] Analytics overview shows counts (admin only)
- [ ] Verification queue lists pending profiles
- [ ] Approve / reject updates status + sends email (with SMTP)

## Backend + DB

- [ ] `GET /health` → 200
- [ ] `docker compose -f docker-compose.prod.yml up` healthy
- [ ] `docs/audit-logs.sql` applied in Supabase
- [ ] Daily backup visible in Supabase dashboard
- [ ] SMTP configured for registration + reminders

## Performance (QA load test)

Run `docs/load-test-public.ps1` against staging:

- [ ] 100 concurrent public reads
- [ ] P95 latency < 500ms

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product | | | |
| QA | | | |
| Tech lead | | | |
