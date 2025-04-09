#!/bin/bash
set -e

# Wait for DB
echo "🔄 Waiting for PostgreSQL..."
until pg_isready -h "$DB_HOST" -p 5432 -U "$POSTGRES_USER" > /dev/null 2>&1; do
  sleep 1
done

echo "✅ PostgreSQL is up. Running setup..."

# Setup DB
bundle exec rails db:prepare

# Start server
echo "🚀 Starting Rails app..."
exec bundle exec rails server -b 0.0.0.0 -p 3000