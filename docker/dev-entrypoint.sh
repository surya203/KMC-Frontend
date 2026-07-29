#!/usr/bin/env bash
# Start Flutter web-server and auto hot-restart when FE source changes.
set -euo pipefail

cd /app

touch .env

echo "[fe-dev] API_BASE_URL=${API_BASE_URL:-http://200.141.2.90:8001}"
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

fingerprint() {
  find lib web assets pubspec.yaml pubspec.lock \
    -type f \( \
      -name '*.dart' -o -name '*.js' -o -name '*.html' -o -name '*.css' \
      -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \
      -o -name 'pubspec.lock' \
    \) 2>/dev/null \
    | sort \
    | xargs md5sum 2>/dev/null \
    | md5sum \
    | awk '{print $1}'
}

PREV="$(fingerprint || true)"
echo "[fe-dev] watching lib/ web/ assets/ â€” edit code, then refresh the browser"

while kill -0 "$FLUTTER_PID" 2>/dev/null; do
  sleep 2
  CUR="$(fingerprint || true)"
  if [[ -n "$CUR" && "$CUR" != "$PREV" ]]; then
    echo "[fe-dev] code change detected -> hot restart (R)"
    printf 'R\n' >&3
    PREV="$CUR"
    sleep 3
  fi
done

wait "$FLUTTER_PID"
