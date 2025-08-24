# Booktar Container

A containerized version of [booktar](https://github.com/TheRealShadoh/booktarr) - a full-stack application for managing book collections with metadata enrichment, local caching, and edition tracking.

## Features

- **Multi-Architecture Support**: Supports AMD64, ARM64, and ARMv7 architectures
- **Automatic Updates**: Monitors upstream repository and rebuilds when changes are detected
- **Minimal Size**: Multi-stage Docker build for optimized image size
- **Security**: Runs as non-root user with proper permissions
- **Universal Compatibility**: Works on Unraid, Ubuntu, RHEL, and other Linux distributions

## Quick Start

### Using Docker Compose (Recommended)

1. Download the docker-compose.yml file:
```bash
curl -O https://raw.githubusercontent.com/TheRealShadoh/booktar-container/main/docker-compose.yml
```

2. Start the application:
```bash
docker-compose up -d
```

3. Access the application:
   - Backend API: http://localhost:8000
   - Frontend: http://localhost:3000

### Using Docker Run

```bash
docker run -d \
  --name booktar \
  -p 8000:8000 \
  -p 3000:3000 \
  -v booktar_data:/app/data \
  -v booktar_cache:/app/cache \
  -e DATABASE_URL=sqlite:///app/data/booktar.db \
  -e CACHE_FILE=/app/cache/books.json \
  --restart unless-stopped \
  ghcr.io/therealshadoh/booktar-container:latest
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Database connection string | `sqlite:///app/data/booktar.db` |
| `CACHE_FILE` | Path to JSON cache file | `/app/cache/books.json` |
| `API_RATE_LIMIT_DELAY` | Delay between API calls (seconds) | `1` |
| `GOOGLE_BOOKS_API_KEY` | Google Books API key (optional) | - |

### Volumes

| Path | Description |
|------|-------------|
| `/app/data` | Database and persistent data |
| `/app/cache` | Cache files and temporary data |

### Ports

| Port | Service |
|------|---------|
| `8000` | Backend API |
| `3000` | Frontend web interface |

## Advanced Usage

### Custom Environment File

Create a `.env` file:
```env
GOOGLE_BOOKS_API_KEY=your_api_key_here
API_RATE_LIMIT_DELAY=2
DATABASE_URL=sqlite:///app/data/booktar.db
CACHE_FILE=/app/cache/books.json
```

Use with docker-compose:
```bash
docker-compose --env-file .env up -d
```

### Health Checks

The container includes a built-in health check that monitors the backend API:
```bash
docker exec booktar curl -f http://localhost:8000/health
```

### Logs

View container logs:
```bash
docker logs booktar
# or with docker-compose
docker-compose logs booktar
```

## Platform-Specific Instructions

### Unraid

1. Go to **Docker** tab in Unraid web interface
2. Click **Add Container**
3. Configure the following:
   - **Name**: `booktar`
   - **Repository**: `ghcr.io/therealshadoh/booktar-container:latest`
   - **Port Mappings**: 
     - Container Port: `8000`, Host Port: `8000`
     - Container Port: `3000`, Host Port: `3000`
   - **Volume Mappings**:
     - Container Path: `/app/data`, Host Path: `/mnt/user/appdata/booktar/data`
     - Container Path: `/app/cache`, Host Path: `/mnt/user/appdata/booktar/cache`

### Portainer

1. Go to **Stacks** in Portainer
2. Click **Add Stack**
3. Paste the docker-compose.yml content
4. Deploy the stack

### Watchtower Integration

Add labels for automatic updates:
```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

## Development

### Building Locally

Build for your platform:
```bash
docker build -t booktar-local .
```

Build for multiple platforms:
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t booktar-multi .
```

### Custom Build Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `REPO_URL` | Upstream repository URL | `https://github.com/TheRealShadoh/booktarr.git` |
| `BRANCH` | Branch to build from | `main` |

Example:
```bash
docker build \
  --build-arg REPO_URL=https://github.com/yourfork/booktarr.git \
  --build-arg BRANCH=develop \
  -t booktar-custom .
```

## Automatic Updates

This repository uses GitHub Actions to automatically:

1. **Monitor**: Check the upstream repository every hour for changes
2. **Build**: Create new container images when updates are detected
3. **Push**: Publish images to GitHub Container Registry
4. **Test**: Verify the container starts and responds correctly

### Manual Triggers

Force a build manually:
1. Go to the **Actions** tab in GitHub
2. Select **Build and Deploy Container**
3. Click **Run workflow**
4. Choose "Force build even if no upstream changes"

## Troubleshooting

### Container Won't Start

Check logs for errors:
```bash
docker logs booktar
```

Common issues:
- Port conflicts: Ensure ports 8000 and 3000 are available
- Permission issues: Verify volume mount permissions
- Resource constraints: Ensure sufficient memory/CPU

### Health Check Failures

The health check endpoint is `/health`. If failing:
```bash
# Check if the backend is responding
curl http://localhost:8000/health

# Check container status
docker inspect booktar --format='{{.State.Health.Status}}'
```

### Database Issues

Reset the database by removing the data volume:
```bash
docker-compose down
docker volume rm booktar-container_booktar_data
docker-compose up -d
```

## Support

- **Issues**: Report bugs and feature requests at [GitHub Issues](https://github.com/TheRealShadoh/booktar-container/issues)
- **Upstream**: For application-specific issues, see [booktarr repository](https://github.com/TheRealShadoh/booktarr)

## License

This project is licensed under the MIT License - see the upstream [booktarr repository](https://github.com/TheRealShadoh/booktarr) for details.

## Acknowledgments

- Original application: [booktarr](https://github.com/TheRealShadoh/booktarr) by TheRealShadoh
- Container automation and multi-architecture support provided by this repository