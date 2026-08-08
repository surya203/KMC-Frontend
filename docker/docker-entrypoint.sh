#!/bin/sh
set -eu

cat > /usr/share/nginx/html/env-config.js <<EOF
window.__ENV__ = {
  ENV: "${ENV:-production}",
  API_BASE_URL: "${API_BASE_URL:-https://api.kmcalumni.net}",
  API_PREFIX: "${API_PREFIX:-/api/v1}",
  STORAGE_BUCKET: "${STORAGE_BUCKET:-verification-documents}",
  SUPABASE_URL: "${SUPABASE_URL:-}",
  SUPABASE_ANON_KEY: "${SUPABASE_ANON_KEY:-}",
  RAZORPAY_KEY_ID: "${RAZORPAY_KEY_ID:-rzp_live_TGwiguT5HZKaNR}",
  SUPABASE_STORAGE_BUCKET: "${SUPABASE_STORAGE_BUCKET:-verification-documents}"
};
EOF

exec "$@"