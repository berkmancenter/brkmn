#!/bin/bash

# Starts the development environment (app + db).
# Extra arguments are passed to `docker compose up`, e.g. `-d` or `--build`.

set -e
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  cp .env.sample .env
  echo "Created .env from .env.sample"
fi

echo "App: http://localhost:8507, Mailcatcher: http://localhost:8517"

exec docker compose -f docker/docker-compose.dev.yml --env-file .env up "$@"
