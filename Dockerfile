FROM python:3.10 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and local BasicSR, then install into /install (includes console scripts)
COPY requirements.txt ./
COPY BasicSR/ ./BasicSR/
RUN pip install --no-cache-dir --prefix /install -r requirements.txt

# --- Final Runtime Stage ---
FROM python:3.10-slim

# Install runtime dependencies (including libGL for OpenCV)
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed Python packages and console scripts from builder
COPY --from=builder /install/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /install/bin /usr/local/bin

# Copy application code
COPY app.py ./

# Create directories for models and cache
RUN mkdir -p /app/models /app/cache

# Download the correct anime model
RUN wget -O /app/models/RealESRGAN_x4plus_anime_6B.pth \
    https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth

# Expose and run
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
