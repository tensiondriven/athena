FROM python:3.11-slim

# Install system dependencies for screenshots (if needed)
RUN apt-get update && apt-get install -y \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY athena-collector-macos.py .

# Create data directory
RUN mkdir -p /data/files

# Expose API port
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5001/health')"

# Run the collector
CMD ["python", "athena-collector-macos.py"]