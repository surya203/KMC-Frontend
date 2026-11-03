# Medical Council Registration Certificate Upload — Design

**Date:** 2026-07-29  
**Status:** Awaiting user review  
**Site:** https://kmcalumni.net/  
**Repos:** KMC-Frontend + KMC-Backend (Postgres via pgAdmin)

## Goal

During Join Network registration, require a **Medical Council Registration Certificate** upload on the **Details** step (alongside optional profile photo). Email OTP remains mandatory afterward. Do not reuse `/register/verify/document` (that path marks the draft verified and skips OTP).

## Chosen approach

Mirror the existing profile-photo draft upload:

1. Upload file to storage during Details.
2. Save path on draft JSON payload.
3. Keep OTP as the verification method.
4. Enforce presence before payment/complete.
5. Copy path onto `alumni_profiles` after successful registration.

## User flow

```
Plan → Details (form + optional photo + mandatory council certificate)
     → Verify (email OTP)
     → Payment
     → Complete
```

- Label: **Medical Council Registration Certificate** (required)
- Allowed types: PDF, JPG, PNG
- Max size: 5 MB
- Continue on Details is blocked until a file is selected
- On Continue: update draft → upload photo if any → upload certificate → advance to Verify

## Backend

### New endpoint

`POST /api/v1/auth/register/draft/{draft_id}/council-certificate`

- Public (same as draft photo)
- Multipart field: `file`
- Validate type/size (PDF/JPG/PNG, ≤ 5 MB)
- Store in existing `verification-documents` bucket (reuse upload helper or thin wrapper)
- Persist draft payload key: `council_certificate_path`
- Does **not** set `verified_at` / `verification_token` / `verification_method`

### Service changes

- `RegistrationService.attach_council_certificate(draft_id, path)` — merge payload like `attach_profile_photo`
- Checkout / complete registration: reject with 422 if `council_certificate_path` is missing
- `_complete_registration` / `create_from_draft`: pass certificate URL into alumni profile

### Out of scope for this change

- Changing `/register/verify/document` behavior
- Admin UI document viewer (optional follow-up; storage path will exist on profile)
- Extra text fields (council name / registration number) unless requested later

## Database (pgAdmin / Postgres)

Drafts already store JSON `payload` — **no** `registration_drafts` column change.

Run once on production:

```sql
ALTER TABLE public.alumni_profiles
  ADD COLUMN IF NOT EXISTS council_certificate_url TEXT;
```

Backend insert should tolerate missing column only if needed for staged rollout; preferred path is run migration before deploy.

## Frontend

| File | Change |
|------|--------|
| `lib/core/network/registration_service.dart` | Add `uploadDraftCouncilCertificate` |
| `lib/features/membership/presentation/membership_screen.dart` | Required picker UI on Details; upload on continue; block without file |

Reuse existing FilePicker patterns from profile photo / former document upload. Clear error if upload fails.

## Error handling

| Case | Behavior |
|------|----------|
| No file selected | Block Continue; show inline required message |
| File too large / wrong type | Client check + show API error |
| Upload fails | Stay on Details; show error; do not advance |
| Missing path at checkout | Backend 422; frontend shows message |

## Testing (production-safe checks)

Full E2E payment testing may be limited; verify:

1. Details UI shows required certificate field
2. Continue without file does not advance
3. With file: API stores `council_certificate_path` on draft (confirm via API GET draft or DB `payload`)
4. OTP still required after upload
5. After a real/test registration, `alumni_profiles.council_certificate_url` is populated

## Deploy order

1. Run pgAdmin SQL (`council_certificate_url`)
2. Deploy KMC-Backend
3. Deploy KMC-Frontend (web build for kmcalumni.net)

## Success criteria

- New registrants cannot leave Details without uploading the certificate
- OTP still required
- Certificate file is stored and linked on the alumni profile after payment completes
