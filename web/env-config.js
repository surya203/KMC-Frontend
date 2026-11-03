// Local/dev defaults. Docker overwrites this via docker/dev-entrypoint.sh.
window.__ENV__ = {
  ENV: 'development',
  API_BASE_URL: 'http://192.168.0.17:8001',
  API_PREFIX: '/api/v1',
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  SUPABASE_STORAGE_BUCKET: 'verification-documents',
};
