#!/bin/bash
set -e
set -x

echo "Starting initialization script"

# Ensure PostgreSQL is running
service postgresql start

# Set up PostgreSQL
su postgres -c "psql -c \"CREATE USER username WITH PASSWORD 'password' SUPERUSER;\""
su postgres -c "createdb -O username data_base_hackathon_development"

# Setup Rails database
echo "Setting up database"
RAILS_ENV=development rails db:create || echo "Database creation failed"
RAILS_ENV=development rails db:migrate || echo "Database migration failed"

echo "Initialization script completed"