// Local/dev defaults. Production Docker overwrites this file from API_BASE_URL.
// Private hosts use the API on the same machine. A public host does not.
(function () {
  var host = (window.location && window.location.hostname) || '';
  function isPrivate(value) {
    if (value === 'localhost' || value === '127.0.0.1') return true;
    var parts = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(value);
    if (!parts) return false;
    var a = +parts[1];
    var b = +parts[2];
    if (a === 10) return true;
    if (a === 192 && b === 168) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    return false;
  }
  var localApi = isPrivate(host) ? 'http://' + host + ':8001' : '';
  window.__ENV__ = {
    ENV: localApi ? 'development' : 'production',
    API_BASE_URL: localApi,
    API_PREFIX: '/api/v1',
    STORAGE_BUCKET: 'verification-documents',
    SUPABASE_URL: '',
    SUPABASE_ANON_KEY: '',
    SUPABASE_STORAGE_BUCKET: 'verification-documents',
  };
})();
