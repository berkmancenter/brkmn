#!/bin/sh

set -eu

cd "$(dirname "$0")/.."

SECRET_KEY_BASE_DUMMY="${SECRET_KEY_BASE_DUMMY:-1}" bundle exec rails assets:precompile
