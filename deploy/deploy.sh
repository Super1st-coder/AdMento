#!/usr/bin/env bash
# Deploy AdMento on the VPS: sync to origin/main and rebuild/restart changed services.
# Runs from GitHub Actions (forced SSH command) or by hand:  bash /opt/admento/deploy/deploy.sh
set -euo pipefail

APP_DIR=/opt/admento
BRANCH=main
exec 9>/tmp/admento-deploy.lock
flock -n 9 || { echo "Another deploy is running; exiting."; exit 1; }

cd "$APP_DIR"
echo "==> Updating code"
git fetch --prune origin "$BRANCH"
git reset --hard "origin/$BRANCH"
echo "    now at $(git log -1 --format='%h %s')"

if [ ! -f .env.deploy ]; then
  echo "ERROR: $APP_DIR/.env.deploy is missing (see deploy/env.deploy.example)"; exit 1
fi

echo "==> Building and starting containers"
docker compose -p admento --env-file .env.deploy -f deploy/docker-compose.yml up -d --build --remove-orphans

echo "==> Cleaning up old AdMento images"
docker image prune -f --filter "label=com.docker.compose.project=admento" >/dev/null || true

echo "==> Status"
docker compose -p admento --env-file .env.deploy -f deploy/docker-compose.yml ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
