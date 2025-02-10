#!/bin/bash

# Define main env file
# Include the environment file in .bashrc if not already included
MAIN_ENV_FILE=".env.${APP_ENV}"
BASHRC_FILE="/home/brkmn/.bashrc"
INCLUDE_LINE=". $MAIN_ENV_FILE"

# Create the environment file if it doesn't exist
if [ ! -f "$MAIN_ENV_FILE" ]; then
  cp .env.sample "$MAIN_ENV_FILE"
  sed -i "s/development/${APP_ENV}/g" "$MAIN_ENV_FILE"
fi

echo "🔍 Loading environment: $APP_ENV"

if ! grep -Fxq "$INCLUDE_LINE" "$BASHRC_FILE"; then
  echo "$INCLUDE_LINE" >> "$BASHRC_FILE"
  echo "✅ Added $MAIN_ENV_FILE to $BASHRC_FILE"
  while IFS='=' read -r key value; do
    if [[ ! -z "$key" ]]; then
      export "$key"="$value"
    fi
  done < <(grep -v '^#\|^$' "$MAIN_ENV_FILE")
else
  echo "✅ $MAIN_ENV_FILE is already included in $BASHRC_FILE"
fi

echo "🚀 Starting Rails app in $APP_ENV environment"

# Check if SMTP_ADDRESS is set, otherwise default to Mailcatcher
if [ -z "$SMTP_ADDRESS" ]; then
  echo "SMTP_ADDRESS not set. Using Mailcatcher..."
  export SMTP_ADDRESS="localhost"
  export SMTP_PORT="1025"

  mailcatcher --ip=0.0.0.0 --smtp-port=1025 --http-port=1080 &
  echo "Mailcatcher started on port 1025 (SMTP) and 1080 (Web UI)"
fi

# Precompiling assets
if [ "$APP_ENV" = "production" ]; then
  SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
fi

# Migrate or setup the database
if ./bin/rails db:migrate 2>/dev/null; then
  echo "Migrations ran successfully."
else
  echo "Migrations failed, setting up the database..."
  ./bin/rails db:setup && ./bin/rails db:migrate
fi

# Execute the main process
exec "$@"
