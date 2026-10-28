#!/bin/bash

# Stops the development environment.
# Extra arguments are passed to `docker compose down`, e.g. `-v` to also drop the database.

set -e
cd "$(dirname "$0")/.."

exec docker compose -f docker/docker-compose.dev.yml --env-file .env down "$@"
