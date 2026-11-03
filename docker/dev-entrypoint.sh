#!/usr/bin/env bash
# Start Flutter web-server. Hot-restart is OFF by default (avoids reload loops
# on Windows bind mounts). Set ENABLE_HOT_RESTART=1 to watch lib/*.dart only.
set -euo pipefail

cd /app

touch .env

API_BASE_URL="${API_BASE_URL:-http://192.168.0.10:8001}"
# Write env-config only when content changes — avoids false file-watch triggers.
ENV_CONFIG_TMP="$(mktemp)"
cat > "$ENV_CONFIG_TMP" <<EOF
window.__ENV__ = {
  ENV: '${ENV:-development}',
  API_BASE_URL: '${API_BASE_URL}',
  API_PREFIX: '${API_PREFIX:-/api/v1}',
  SUPABASE_URL: '${SUPABASE_URL:-}',
  SUPABASE_ANON_KEY: '${SUPABASE_ANON_KEY:-}',
  SUPABASE_STORAGE_BUCKET: '${SUPABASE_STORAGE_BUCKET:-verification-documents}',
};
EOF
if ! cmp -s "$ENV_CONFIG_TMP" /app/web/env-config.js 2>/dev/null; then
  cp "$ENV_CONFIG_TMP" /app/web/env-config.js
fi
rm -f "$ENV_CONFIG_TMP"

echo "[fe-dev] API_BASE_URL=${API_BASE_URL}"
echo "[fe-dev] flutter pub get..."
flutter pub get

FIFO=/tmp/flutter_cmd
rm -f "$FIFO"
mkfifo "$FIFO"

# Keep FIFO open (read+write) so flutter stdin never gets EOF
exec 3<>"$FIFO"

echo "[fe-dev] starting Flutter web-server on 0.0.0.0:8080 ..."
flutter run -d web-server \
  --web-hostname=0.0.0.0 \
  --web-port=8080 \
  --no-pub \
  <&3 &
FLUTTER_PID=$!

if [[ "${ENABLE_HOT_RESTART:-0}" != "1" ]]; then
  echo "[fe-dev] hot-restart watcher OFF (stable page loads). Set ENABLE_HOT_RESTART=1 to enable."
  wait "$FLUTTER_PID"
  exit $?
fi

fingerprint() {
  # Only Dart sources — never watch web/env-config.js or assets (Windows churn).
  find lib -type f -name '*.dart' 2>/dev/null \
    | sort \
    | xargs md5sum 2>/dev/null \
    | md5sum \
    | awk '{print $1}'
}

PREV="$(fingerprint || true)"
echo "[fe-dev] watching lib/*.dart for hot restart"

while kill -0 "$FLUTTER_PID" 2>/dev/null; do
  sleep 5
  CUR="$(fingerprint || true)"
  if [[ -n "$CUR" && -n "$PREV" && "$CUR" != "$PREV" ]]; then
    echo "[fe-dev] dart change detected -> hot restart (R)"
    printf 'R\n' >&3
    PREV="$CUR"
    sleep 5
  fi
done

wait "$FLUTTER_PID"
