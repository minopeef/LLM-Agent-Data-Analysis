# Multi-stage build for optimized image size
# Stage 1: Build dependencies
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim as builder

# Set environment variables for build
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

# Set work directory
WORKDIR /app

# Install system dependencies for building
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install --no-cache-dir uv

# Copy project definition files first (for better layer caching)
COPY pyproject.toml ./
# Copy lock file if it exists
COPY uv.lock* ./

# Install dependencies (this layer will be cached if pyproject.toml doesn't change)
RUN uv pip install --system --no-cache -e .

# Stage 2: Runtime image
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Set work directory
WORKDIR /app

# Install only runtime system dependencies (no build tools needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install uv for runtime (lighter than full pip)
RUN pip install --no-cache-dir uv

# Copy installed packages from builder stage
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Collect static files (if needed)
RUN python manage.py collectstatic --noinput || true

# Expose the port the app runs on
EXPOSE 8000

# Specify the command to run on container start using Uvicorn
CMD ["uvicorn", "ragstar.asgi:application", "--host", "0.0.0.0", "--port", "8000"]
