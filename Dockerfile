# 1) Builder stage: install your local BasicSR, all Python deps, and fetch the model weights
FROM python:3.10-slim AS builder
WORKDIR /app

# Copy requirements and your edited BasicSR library
COPY requirements.txt .
COPY BasicSR/ ./BasicSR/

# Install build & network tools
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential git wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install Python packages (including -e ./BasicSR)
RUN pip install --no-cache-dir --prefix /install -r requirements.txt

# Download the Real-ESRGAN weights into a known path
RUN mkdir -p /weights \
 && wget -q -O /weights/RealESRGAN_x4plus.pth \
      https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus.pth

# 2) Final runtime image: lean, no wget needed here
FROM python:3.10-slim
WORKDIR /app

# Runtime libraries for OpenCV, GL, etc.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libglib2.0-0 libsm6 libxrender1 libxext6 libgl1 libgl1-mesa-glx \
 && rm -rf /var/lib/apt/lists/*

# Copy in installed Python packages
COPY --from=builder /install /usr/local

# Copy app code (and BasicSR if your runtime imports it directly)
COPY app.py .
COPY BasicSR/ ./BasicSR/

# Copy the pre‑downloaded weights
RUN mkdir -p models cache
COPY --from=builder /weights/RealESRGAN_x4plus.pth models/

EXPOSE 80
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
