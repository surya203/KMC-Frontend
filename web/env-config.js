// Local/dev defaults. Docker overwrites this via docker/docker-entrypoint.sh.
// Each developer sets API_BASE_URL in `.env` (see `.env.example`).
window.__ENV__ = window.__ENV__ || {
  ENV: 'production',
  API_BASE_URL: 'http://200.141.2.90:8001',
  API_PREFIX: '/api/v1',
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  RAZORPAY_KEY_ID: 'rzp_test_TGszsSr6SOtWXB',
  SUPABASE_STORAGE_BUCKET: 'verification-documents',
};
