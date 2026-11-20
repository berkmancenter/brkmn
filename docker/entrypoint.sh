#!/bin/bash

# Define main env file.
# Include the environment file in .bashrc if not already included.
MAIN_ENV_FILE=".env.${APP_ENV}"
BASHRC_FILE="/home/brkmn/.bashrc"
INCLUDE_LINE=". $MAIN_ENV_FILE"

# This key was committed in .env.sample, so it is public and must never be used.
PUBLIC_SAMPLE_SECRET="125f58a21a6c72b165a8c84c6660a2b16cadd8f9894cdfd3d07ab266e09e9ae26e8346b14afe781148d6115980aeb1e1fb59833ae0d9512f12e2aef06e046d27"

new_secret() {
  ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
}

# Create the environment file if it doesn't exist, with its own secret key.
if [ ! -f "$MAIN_ENV_FILE" ]; then
  cp .env.sample "$MAIN_ENV_FILE"
  sed -i "s/development/${APP_ENV}/g" "$MAIN_ENV_FILE"
  sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$(new_secret)/" "$MAIN_ENV_FILE"
  echo "✅ Created $MAIN_ENV_FILE with a new SECRET_KEY_BASE"
fi

# Older env files were copied with the public sample key. Replace it, this
# signs out everybody once.
if grep -q "^SECRET_KEY_BASE=${PUBLIC_SAMPLE_SECRET}" "$MAIN_ENV_FILE"; then
  sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$(new_secret)/" "$MAIN_ENV_FILE"
  echo "⚠️  Replaced the public sample SECRET_KEY_BASE in $MAIN_ENV_FILE with a new one"
fi

echo "🔍 Loading environment: $APP_ENV"

# Include the environment file in .bashrc if not already included (for shells
# opened in the container).
if ! grep -Fxq "$INCLUDE_LINE" "$BASHRC_FILE"; then
  echo "$INCLUDE_LINE" >> "$BASHRC_FILE"
  echo "✅ Added $MAIN_ENV_FILE to $BASHRC_FILE"
fi

# Export the environment variables on every start. The server doesn't read
# .bashrc, so without this a restarted container runs without its settings.
# Values are taken literally (no shell expansion), e.g. "\n" in certificates.
while IFS='=' read -r key value; do
  if [[ -n "$key" ]]; then
    export "$key"="$value"
  fi
done < <(grep -v '^#\|^$' "$MAIN_ENV_FILE")

echo "🚀 Starting Rails app in $APP_ENV environment"

# Check if SMTP_ADDRESS is set, otherwise default to Mailcatcher.
# Mailcatcher shows every mail to anyone who can reach it, so never in production.
if [ -z "$SMTP_ADDRESS" ]; then
  if [ "$APP_ENV" = "development" ] || [ "$APP_ENV" = "test" ]; then
    echo "SMTP_ADDRESS not set. Using Mailcatcher..."
    export SMTP_ADDRESS="localhost"
    export SMTP_PORT="1025"

    mailcatcher --ip=0.0.0.0 --smtp-port=1025 --http-port=1080 &
    echo "Mailcatcher started on port 1025 (SMTP) and 1080 (Web UI)"
  else
    echo "⚠️  SMTP_ADDRESS not set, emails will not be delivered"
  fi
fi

# Remove server pid if it exists.
rm -f tmp/pids/server.pid

# Precompiling assets.
if [ "$APP_ENV" = "production" ]; then
  SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
fi

# Create the database if needed, otherwise run pending migrations.
# (The old "db:setup when migrate fails" could load the schema over real data.)
if ! ./bin/rails db:prepare; then
  # Production must not start on a half migrated database. In development the
  # start command installs new gems first and runs db:prepare again.
  if [ "$APP_ENV" = "production" ]; then
    echo "❌ Database setup or migration failed"
    exit 1
  fi
  echo "⚠️  Database setup or migration failed, continuing"
fi

# Execute the main process.
exec "$@"
