// Local/dev defaults. Docker overwrites this via docker/docker-entrypoint.sh.
// Each developer sets API_BASE_URL in `.env` (see `.env.example`).
window.__ENV__ = window.__ENV__ || {
  ENV: 'development',
  API_BASE_URL: 'http://192.168.0.2:8001',
  API_PREFIX: '/api/v1',
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  RAZORPAY_KEY_ID: 'rzp_test_T6cRniAkd0zVdl',
  SUPABASE_STORAGE_BUCKET: 'verification-documents',
};
