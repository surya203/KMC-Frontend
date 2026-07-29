// Runtime web defaults. Docker/prod overwrites this via docker/docker-entrypoint.sh.
// Do not edit sir's `.env` / `.env.production`.
window.__ENV__ = window.__ENV__ || {
  ENV: 'production',
  API_BASE_URL: 'https://api.kmcalumni.net',
  API_PREFIX: '/api/v1',
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  // Public checkout key only — secret stays on backend.
  RAZORPAY_KEY_ID: 'rzp_live_TGwiguT5HZKaNR',
  SUPABASE_STORAGE_BUCKET: 'verification-documents',
};
