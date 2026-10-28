#!/bin/bash

# Opens a shell in the running development app container.
# Pass a command to run it instead, e.g. `./docker/shell_dev.sh bin/rails console`.

set -e
cd "$(dirname "$0")/.."

if [ $# -eq 0 ]; then
  set -- bash
fi

exec docker compose -f docker/docker-compose.dev.yml --env-file .env exec app "$@"
