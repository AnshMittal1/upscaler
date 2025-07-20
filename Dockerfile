# 1) Builder stage: install your local BasicSR and all Python deps
FROM python:3.10-slim AS builder
WORKDIR /app

COPY requirements.txt .
COPY BasicSR/ ./BasicSR/

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential git wget \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --prefix /install -r requirements.txt

# 2) Final runtime image
FROM python:3.10-slim
WORKDIR /app

# Install runtime dependencies (including wget for the model download)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      wget libglib2.0-0 libsm6 libxrender1 libxext6 libgl1 libgl1-mesa-glx \
 && rm -rf /var/lib/apt/lists/*

# Copy in installed Python packages
COPY --from=builder /install /usr/local

# Copy app code (and BasicSR if it's needed at runtime)
COPY app.py .
COPY BasicSR/ ./BasicSR/

# Prepare model & cache directories and download weights
RUN mkdir -p models cache \
 && wget -q -O models/RealESRGAN_x4plus.pth \
    https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus.pth

EXPOSE 80
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
