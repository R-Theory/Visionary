# Visionary Workers - Celery Background Jobs
# Used for TTS processing, knowledge ingestion, and AI tasks

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY workers/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY workers/ /app/workers/
COPY shared/ /app/shared/

# Set Python path
ENV PYTHONPATH=/app

# Create non-root user for security
RUN groupadd -r celery && useradd -r -g celery celery
RUN chown -R celery:celery /app
USER celery

# Default command (can be overridden in docker-compose)
CMD ["celery", "-A", "workers.celery_app", "worker", "--loglevel=info"]
