// Local/dev defaults. Docker overwrites this via docker/dev-entrypoint.sh.
// On localhost, prefer loopback API; on LAN pages use the current machine IP pattern.
(function () {
  var host = (window.location && window.location.hostname) || '';
  var isLocal = host === 'localhost' || host === '127.0.0.1';
  window.__ENV__ = {
    ENV: 'development',
    API_BASE_URL: isLocal ? 'http://127.0.0.1:8001' : 'http://192.168.0.17:8001',
    API_PREFIX: '/api/v1',
    STORAGE_BUCKET: 'verification-documents',
    SUPABASE_URL: '',
    SUPABASE_ANON_KEY: '',
    SUPABASE_STORAGE_BUCKET: 'verification-documents',
  };
})();
