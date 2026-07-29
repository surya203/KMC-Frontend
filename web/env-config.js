// Runtime web defaults. Docker/prod overwrites this via docker/docker-entrypoint.sh.
// Do not edit sir's `.env` / `.env.production`.
window.__ENV__ = window.__ENV__ || {
  ENV: 'production',
  API_BASE_URL: 'http://localhost:8001',
  API_PREFIX: '/api/v1',
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  RAZORPAY_KEY_ID: 'rzp_test_TGszsSr6SOtWXB',
  SUPABASE_STORAGE_BUCKET: 'verification-documents',
};
