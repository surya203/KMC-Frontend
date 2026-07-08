# KMC Alumni Connect — QA component list

Handbook §6.2 component inventory mapped to Flutter `ValueKey`s (QA contract).

## Phase 1 — Public shell

| Route | Handbook component | Flutter location | Key examples |
|-------|-------------------|------------------|--------------|
| `/` | HeroSection, StatsBar, FeaturesGrid, GalleryPreview, CtaSection | `home_screen.dart` + widgets | `home-api-status-banner`, `nav-*` |
| `/` | FeaturedAlumniCarousel, TestimonialBlock | `featured_alumni_section.dart`, `reconnect_section.dart` | — |
| `/about` | CMS milestones | `about_screen.dart` | API + fallback |
| `/events`, `/gallery` | Static/API list pages | `events_screen.dart`, `gallery_screen.dart` | — |
| `/splash` | Branded entry | `splash_screen.dart` | — |

## Phase 2 — Auth & membership

| Route | Handbook component | Key examples |
|-------|-------------------|--------------|
| `/auth` | SignInForm, PasswordField | `auth-email-field`, `auth-password-field`, `auth-sign-in-button` (ARIA via Semantics) |
| `/auth/forgot-password` | ForgotPasswordPage | `forgot-password-email-field`, `forgot-password-submit` |
| `/auth/reset-password` | Reset password | `reset-password-token-field`, `reset-password-submit` |
| `/membership` | RegistrationStepper, PlanCard, DetailsForm, VerificationStep, PaymentStep, CompletionStep | `membership-join-button`, `membership-upload-document`, Razorpay step 4 |
| `/dashboard` | DashboardSummary, MembershipBadge | `dashboard-profile-link`, `dashboard-sign-out` |

## Phase 3 — Member features

| Route | Handbook component | Key examples |
|-------|-------------------|--------------|
| `/events/:slug` | EventRegistrationButton, RegistrationCountBadge | `event-register-button` |
| `/gallery/:slug` | AlbumGrid, AlbumCard, MediaLightbox | `gallery-media-{id}`, `gallery-lightbox-close` |
| `/profiles` | Directory search | `directory-search`, `directory-search-button` |
| `/dashboard/profile` | ProfileEditor | `profile-upload-photo`, `profile-save` |
| `/dashboard/announcements` | AnnouncementFeed | `announcement-{id}`, `announcement-create-button`, `announcement-edit-{id}`, `announcement-delete-{id}` |
| `/dashboard/events` | MyEventsPage | `my-event-{id}` |

Home API widgets: `LatestEvents`, `FeaturedAlumniSection`, `GalleryPreview`.

## Phase 4 — Admin

| Route | Handbook component | APIs |
|-------|-------------------|------|
| `/admin` | AnalyticsDashboard | overview + engagement (`admin-engagement-heading`) |
| `/admin/verifications` | VerificationQueue | approve / reject |
| `/admin/members` | MemberTable | search, role, CSV (`admin-members-export`) |
| `/admin/events` | EventEditor | create, edit, delete, reminders |
| `/admin/gallery` | GalleryManager | album CRUD + media upload |

Nav: `member-admin-link` when user has admin access.

## Accessibility (handbook §6.3)

- Sign-in form wrapped with `Semantics(label: 'Sign in form')`
- Registration stepper steps expose `Semantics` labels
- Event register buttons expose `Semantics` labels

## Payment

Razorpay checkout on membership step 4 (web): `checkout.js` in `web/index.html`, order from `POST /api/v1/membership/checkout`.
