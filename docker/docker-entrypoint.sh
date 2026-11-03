#!/bin/sh
set -eu

cat > /usr/share/nginx/html/env-config.js <<EOF
window.__ENV__ = {
  ENV: "${ENV:-production}",
  API_BASE_URL: "${API_BASE_URL:-http://192.168.0.10:8001}",
  API_PREFIX: "${API_PREFIX:-/api/v1}",
  SUPABASE_URL: "${SUPABASE_URL:-}",
  SUPABASE_ANON_KEY: "${SUPABASE_ANON_KEY:-}",
  SUPABASE_STORAGE_BUCKET: "${SUPABASE_STORAGE_BUCKET:-verification-documents}"
};
EOF

exec "$@"
