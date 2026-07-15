// Always overwrite so stale browser cache / old 8004 values cannot stick.
window.__ENV__ = {
  ENV: 'development',
  API_BASE_URL: 'http://localhost:8005',
  API_PREFIX: '/api/v1',
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  RAZORPAY_KEY_ID: '',
  SUPABASE_STORAGE_BUCKET: 'verification-documents',
};
