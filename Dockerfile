FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the Python code
COPY py/ /app/

# Install Python dependencies
RUN pip install --no-cache-dir -e .[core]

# Create a non-root user
RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${R2R_PORT:-8272}/v3/health || exit 1

# Default command
CMD ["uvicorn", "core.main.app_entry:app", "--host", "0.0.0.0", "--port", "8272"]