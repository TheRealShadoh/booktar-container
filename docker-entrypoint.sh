#!/bin/sh
set -e

# Ensure data and cache directories exist with proper permissions
echo "Ensuring data directories exist..."
mkdir -p /app/data /app/cache

# Check if running as root (shouldn't happen, but handle it)
if [ "$(id -u)" = "0" ]; then
    echo "Running as root, adjusting permissions..."
    chown -R booktar:booktar /app/data /app/cache
    chmod 755 /app/data /app/cache
fi

# Verify directories are writable
if [ -w /app/data ]; then
    echo "✓ Data directory is writable"
else
    echo "✗ ERROR: Data directory is not writable"
    ls -la /app/
    exit 1
fi

if [ -w /app/cache ]; then
    echo "✓ Cache directory is writable"
else
    echo "✗ ERROR: Cache directory is not writable"
    ls -la /app/
    exit 1
fi

# Display environment for debugging
echo "Environment variables:"
echo "DATABASE_URL: ${DATABASE_URL}"
echo "CACHE_FILE: ${CACHE_FILE}"
echo "Current user: $(whoami) (UID: $(id -u), GID: $(id -g))"
echo "Working directory: $(pwd)"

# Start the application
echo "Starting Booktarr application..."
exec "$@"