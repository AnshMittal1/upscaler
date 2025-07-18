# ---- Build Stage ----
# Use a full Python image that includes build tools
FROM python:3.10 as builder

# Install system dependencies needed for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      build-essential \
      wget

WORKDIR /app

# Copy only necessary files for dependency installation
COPY requirements.txt .
COPY BasicSR/ ./BasicSR/

# Install Python dependencies
# This includes compiling BasicSR from the local folder
RUN pip install --no-cache-dir -r requirements.txt

# Create directories for the model and cache
RUN mkdir -p /app/models /app/cache

# Download the model
RUN wget -O /app/models/RealESRGAN_x4plus_anime_6B.pth \
    https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus_anime_6B.pth

# ---- Final Stage ----
# Start from a slim, clean Python image
FROM python:3.10-slim

WORKDIR /app

# Install only essential runtime system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libgl1-mesa-glx \
      libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV TORCH_HOME=/app/cache
ENV BASICSR_CACHE=/app/cache

# Copy the installed Python packages from the build stage
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Copy the downloaded model from the build stage
COPY --from=builder /app/models /app/models

# Copy your application code
COPY app.py .

# Expose port and start Uvicorn
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]