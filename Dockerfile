# Production image for KMC Alumni Connect (Flutter web + nginx)

FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
# .env is git/docker-ignored but declared as a bundled asset in pubspec.yaml.
# Create an empty one so the web build succeeds; runtime config is injected
# via docker/docker-entrypoint.sh (window.__ENV__ / env-config.js).
RUN touch .env
RUN flutter build web --release

FROM nginx:1.27-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/docker-entrypoint.sh /tmp/docker-entrypoint.sh
RUN sed -i 's/\r$//' /tmp/docker-entrypoint.sh \
  && printf '%s\n' '#!/bin/sh' > /docker-entrypoint.sh \
  && tail -n +2 /tmp/docker-entrypoint.sh >> /docker-entrypoint.sh \
  && chmod +x /docker-entrypoint.sh \
  && rm -f /tmp/docker-entrypoint.sh

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
