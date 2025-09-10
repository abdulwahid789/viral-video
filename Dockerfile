# Use Python 3.8 slim image as base
FROM python:3.8-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies including FFmpeg for video processing
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    libgtk2.0-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for frontend components
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs

# Set work directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy package.json if it exists and install Node.js dependencies
COPY package*.json ./
RUN npm install || echo "No package.json found, skipping npm install"

# Copy the rest of the application
COPY . .

# Create necessary directories for video processing
RUN mkdir -p /app/input /app/output /app/temp /app/cache

# Set permissions
RUN chmod +x /app/*.py || echo "No Python files to make executable"

# Expose port for the application
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Command to run the application
CMD ["python", "main.py"]
