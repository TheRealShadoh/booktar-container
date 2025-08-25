# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **containerization wrapper repository** for the [booktarr](https://github.com/TheRealShadoh/booktarr) application. It does NOT contain the actual application source code - instead, it provides Docker infrastructure to automatically build, package, and deploy the upstream booktar application as a container.

## Architecture

### Container Build Strategy
- **Multi-stage Docker build** with 4 distinct stages:
  1. `source` - Fetches upstream code via git clone
  2. `frontend-builder` - Builds Node.js frontend assets  
  3. `backend-builder` - Installs Python dependencies
  4. `runtime` - Final minimal Alpine Linux runtime image
- **Multi-architecture support** for amd64, arm64, and armv7
- **Dynamic source fetching** using build args `REPO_URL` and `BRANCH`

### Automated CI/CD Pipeline
The GitHub Actions workflow (`build-and-deploy.yml`) implements a sophisticated update detection system:
- **Upstream monitoring** - Polls the upstream repo hourly for new commits
- **SHA tracking** - Stores last built commit SHA in `.last_built_sha` file
- **Conditional builds** - Only rebuilds when upstream changes detected
- **Multi-platform publishing** to GitHub Container Registry (ghcr.io)

### Key Workflow Jobs
1. `check-upstream` - Compares upstream SHA with last built SHA
2. `build-and-push` - Builds and publishes multi-arch images
3. `test-deployment` - Validates container functionality

## Common Commands

### Building the Container
```bash
# Build for local platform
docker build -t booktar-local .

# Build with custom upstream source
docker build \
  --build-arg REPO_URL=https://github.com/yourfork/booktarr.git \
  --build-arg BRANCH=develop \
  -t booktar-custom .

# Multi-platform build (requires buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t booktar-multi .
```

### Testing and Deployment
```bash
# Test with docker-compose
docker-compose up -d

# Check container health
docker exec booktar curl -f http://localhost:8000/health

# View logs
docker logs booktar
docker-compose logs booktar
```

### Workflow Management
```bash
# Trigger manual build (requires gh CLI)
gh workflow run build-and-deploy.yml -f force_build=true

# Monitor workflow status
gh run list
gh run watch
```

## Environment Configuration

### Runtime Environment Variables
- `DATABASE_URL` - SQLite database path (default: sqlite:///app/data/booktar.db)
- `CACHE_FILE` - JSON cache location (default: /app/cache/books.json)
- `API_RATE_LIMIT_DELAY` - API call delay in seconds (default: 1)
- `GOOGLE_BOOKS_API_KEY` - Optional Google Books API integration

### Build Arguments
- `REPO_URL` - Upstream repository URL (default: https://github.com/TheRealShadoh/booktarr.git)
- `BRANCH` - Git branch to build (default: main)

## Container Specifications

### Ports
- `8000` - Backend Python API
- `3000` - Frontend web interface

### Volumes
- `/app/data` - Database and persistent data
- `/app/cache` - Cache files and temporary data

### Security
- Runs as non-root user `booktar` (UID 1000)
- Uses `tini` as PID 1 init system
- Includes built-in health checks

## Development Workflow

When modifying this containerization infrastructure:

1. **Test Docker builds locally** before pushing
2. **Validate multi-stage dependencies** - ensure each stage copies required artifacts
3. **Check GitHub Actions workflow** - syntax errors will cause CI failures
4. **Monitor upstream changes** - the container automatically tracks the upstream repo
5. **Verify container startup** - test that both frontend and backend services start correctly

## Common Issues

### GitHub Actions Failures
- **Environment variable syntax** - Use `${{ github.event.name }}` not `${{ github.event_name }}`
- **Missing files** - Check that `.last_built_sha` handling includes error cases
- **Multi-platform builds** - Ensure QEMU and buildx are properly configured
- **Registry permissions** - Verify `GITHUB_TOKEN` has package write access

### Docker Build Issues
- **Stage dependencies** - Each stage must copy artifacts from previous stages
- **Path resolution** - Ensure copied paths exist in source containers
- **Platform compatibility** - Test builds on target architectures
- **Health check endpoints** - Verify the application exposes expected health routes

### Container Runtime Issues
- **Port conflicts** - Ensure 8000 and 3000 are available on host
- **Volume permissions** - Check that booktar user can write to mounted volumes
- **Environment variables** - Validate all required env vars are set correctly

## Upstream Dependency

This repository is tightly coupled to the upstream [booktarr](https://github.com/TheRealShadoh/booktarr) project. Changes in the upstream repository's structure, build process, or dependencies may require updates to:
- Dockerfile stage configurations
- Build argument handling
- Runtime environment setup
- Health check implementation