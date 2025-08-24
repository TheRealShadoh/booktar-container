# Multi-stage Dockerfile for booktar application
# Supports multi-architecture builds (amd64, arm64, armv7)

# Stage 1: Source fetcher
FROM alpine/git AS source

ARG REPO_URL=https://github.com/TheRealShadoh/booktarr.git
ARG BRANCH=main

WORKDIR /app
RUN git clone --branch ${BRANCH} --depth 1 ${REPO_URL} .

# Stage 2: Build frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy frontend package files
COPY --from=source frontend/package*.json ./
RUN npm ci --only=production

# Copy frontend source and build
COPY --from=source frontend/ ./
RUN npm run build

# Stage 3: Build backend dependencies
FROM python:3.11-alpine AS backend-builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev

WORKDIR /app

# Copy backend requirements and install
COPY --from=source backend/requirements.txt ./
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 4: Final runtime image
FROM python:3.11-alpine AS runtime

# Create non-root user
RUN addgroup -g 1000 booktar && \
    adduser -u 1000 -G booktar -s /bin/sh -D booktar

# Install runtime dependencies
RUN apk add --no-cache \
    curl \
    tini

# Set working directory
WORKDIR /app

# Copy Python dependencies
COPY --from=backend-builder /root/.local /home/booktar/.local

# Copy application source
COPY --from=source backend/ ./backend/
COPY --from=frontend-builder /app/frontend/build ./frontend/build/

# Create necessary directories and set permissions
RUN mkdir -p /app/data /app/cache && \
    chown -R booktar:booktar /app

# Switch to non-root user
USER booktar

# Add local bin to PATH
ENV PATH=/home/booktar/.local/bin:$PATH

# Set environment variables
ENV PYTHONPATH=/app/backend \
    PYTHONUNBUFFERED=1 \
    DATABASE_URL=sqlite:///app/data/booktar.db \
    CACHE_FILE=/app/cache/books.json \
    API_RATE_LIMIT_DELAY=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose ports
EXPOSE 8000 3000

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["python", "backend/main.py"]

# Metadata
LABEL org.opencontainers.image.title="Booktar Container"
LABEL org.opencontainers.image.description="Containerized version of the booktar book collection management application"
LABEL org.opencontainers.image.source="https://github.com/TheRealShadoh/booktar-container"
LABEL org.opencontainers.image.vendor="TheRealShadoh"
LABEL org.opencontainers.image.licenses="MIT"