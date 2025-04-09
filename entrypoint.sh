#!/bin/bash
set -e

# Wait for DB to be ready
echo "🔄 Waiting for PostgreSQL..."
until pg_isready -h db -p 5432 -U postgres > /dev/null 2>&1; do
  sleep 1
done

echo "✅ PostgreSQL is up. Running setup..."

# DB setup
bundle exec rails db:create db:migrate

# Start server
echo "🚀 Starting Rails app..."
exec bundle exec rails server -b 0.0.0.0 -p 3000