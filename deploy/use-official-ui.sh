#!/usr/bin/env bash

set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_COMPOSE="${DEPLOY_DIR}/docker-compose.yml"
OVERRIDE_COMPOSE="${DEPLOY_DIR}/docker-compose.ghcr.yml"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH" >&2
  exit 1
fi

if [ ! -f "${BASE_COMPOSE}" ]; then
  echo "missing ${BASE_COMPOSE}" >&2
  exit 1
fi

rm -f "${OVERRIDE_COMPOSE}"

echo "Switching back to official image from docker-compose.yml"
docker compose -f "${BASE_COMPOSE}" pull sub2api
docker compose -f "${BASE_COMPOSE}" up -d

echo "Current running image:"
docker inspect --format '{{.Config.Image}}' sub2api

echo "Service status:"
docker compose -f "${BASE_COMPOSE}" ps sub2api
