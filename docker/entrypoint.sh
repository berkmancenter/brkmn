#!/bin/sh

# Function to load environment variables from a file if it exists
load_env_file() {
  if [ -f "$1" ]; then
    echo "✅ Loading $1"
    export $(grep -v '^#' "$1" | xargs)
  else
    echo "⚠️ File $1 not found, skipping..."
  fi
}

# Set default environment if not provided
APP_ENV=${APP_ENV:-production}

# Define main env file
MAIN_ENV_FILE=".env.${APP_ENV}"

echo "🔍 Loading environment: $APP_ENV"

# Load the main environment file and then the local override file
load_env_file "$MAIN_ENV_FILE"

# Check if SMTP_ADDRESS is set, otherwise default to Mailcatcher
if [ -z "$SMTP_ADDRESS" ]; then
  echo "SMTP_ADDRESS not set. Using Mailcatcher..."
  export SMTP_ADDRESS="localhost"
  export SMTP_PORT="1025"

  mailcatcher --ip=0.0.0.0 --smtp-port=1025 --http-port=1080 &
  echo "Mailcatcher started on port 1025 (SMTP) and 1080 (Web UI)"
fi


./bin/rails db:migrate 2>/dev/null || ./bin/rails db:setup && ./bin/rails db:migrate

# Execute the main process
exec "$@"
