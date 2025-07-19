# ---------- Builder Stage ----------
FROM python:3.10 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and BasicSR source, then install into /install
COPY requirements.txt ./
COPY BasicSR/ ./BasicSR/
RUN pip install --no-cache-dir --prefix /install -r requirements.txt

# Copy application code for any code-gen steps (if needed)
COPY app.py ./

# ---------- Runtime Stage ----------
FROM python:3.10-slim AS runtime

# Install system dependencies needed by OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libxext6 \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Create work directory
WORKDIR /app

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy application code and BasicSR (if your app imports it at runtime)
COPY app.py ./
# If BasicSR code is imported dynamically at runtime, uncomment below:
# COPY BasicSR/ ./BasicSR/

# Create models and cache directories
RUN mkdir -p /app/models /app/cache

# Download ESRGAN anime model into models folder
RUN wget -q -O /app/models/RealESRGAN_x4plus_anime_6B.pth \
    https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth

# Expose port and run Uvicorn
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
