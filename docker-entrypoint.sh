#!/bin/sh
set -e

# Ensure data and cache directories exist
echo "Ensuring data directories exist..."
mkdir -p /app/data /app/cache

# Check current ownership
echo "Current directory ownership:"
ls -la /app/ | grep -E "data|cache"

# If directories are owned by root (from volume mounts), we need to work around it
# Since we're running as booktar user, we can't chown, but we can use subdirectories
if [ ! -w /app/data ]; then
    echo "Warning: /app/data is not writable (likely a volume mount owned by root)"
    echo "Creating writable subdirectory /app/data/db..."
    if mkdir -p /app/data/db 2>/dev/null; then
        echo "✓ Created writable subdirectory"
        export DATABASE_URL="sqlite:///app/data/db/booktar.db"
    else
        echo "✓ Using in-container data directory instead"
        mkdir -p /tmp/booktar-data
        export DATABASE_URL="sqlite:////tmp/booktar-data/booktar.db"
    fi
else
    echo "✓ Data directory is writable"
fi

if [ ! -w /app/cache ]; then
    echo "Warning: /app/cache is not writable (likely a volume mount owned by root)"
    echo "Creating writable subdirectory /app/cache/data..."
    if mkdir -p /app/cache/data 2>/dev/null; then
        echo "✓ Created writable subdirectory"
        export CACHE_FILE="/app/cache/data/books.json"
    else
        echo "✓ Using in-container cache directory instead"
        mkdir -p /tmp/booktar-cache
        export CACHE_FILE="/tmp/booktar-cache/books.json"
    fi
else
    echo "✓ Cache directory is writable"
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