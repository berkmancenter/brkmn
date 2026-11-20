#!/bin/bash

# Demo data in the running development app container (see "Demo data" in README.md).
#
#   ./docker/seed_dev.sh          load it (again: back to its starting state)
#   ./docker/seed_dev.sh reset    remove it and load it again
#   ./docker/seed_dev.sh remove   remove it, other data stays
#   ./docker/seed_dev.sh info     show the demo accounts and things to try
#
# DEMO_GENERATED_LINKS, DEMO_PASSWORD and DEMO_RANDOM_SEED are passed on, e.g.
# `DEMO_GENERATED_LINKS=1000 ./docker/seed_dev.sh reset`.

set -e
cd "$(dirname "$0")/.."

command="${1:-load}"
case "$command" in
  load | reset | remove | info) ;;
  *)
    echo "Usage: $0 [load|reset|remove|info]" >&2
    exit 1
    ;;
esac

env_args=()
for name in DEMO_GENERATED_LINKS DEMO_PASSWORD DEMO_RANDOM_SEED; do
  if [ -n "${!name}" ]; then
    env_args+=(-e "$name=${!name}")
  fi
done

exec docker compose -f docker/docker-compose.dev.yml --env-file .env exec "${env_args[@]}" app bin/rails "demo:$command"
