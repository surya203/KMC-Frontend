// Runtime web defaults. Docker/prod overwrites this via docker/docker-entrypoint.sh.
// On localhost, use the local API (port 8000) so Chrome login is not blocked by CORS.
(function () {
  var host = (window.location && window.location.hostname) || '';
  var isLocal = host === 'localhost' || host === '127.0.0.1';
  window.__ENV__ = {
    ENV: isLocal ? 'development' : 'production',
    API_BASE_URL: isLocal ? 'http://127.0.0.1:8000' : 'https://api.kmcalumni.net',
    API_PREFIX: '/api/v1',
    STORAGE_BUCKET: 'verification-documents',
    SUPABASE_URL: '',
    SUPABASE_ANON_KEY: '',
    RAZORPAY_KEY_ID: 'rzp_live_TGwiguT5HZKaNR',
    SUPABASE_STORAGE_BUCKET: 'verification-documents',
  };
})();
