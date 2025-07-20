# Dockerfile

# 1) Build stage: install everything, including your local BasicSR
FROM python:3.10-slim AS builder
WORKDIR /app

# Copy requirements and your edited BasicSR library
COPY requirements.txt .
COPY BasicSR/ ./BasicSR/

# System deps for build
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential git wget \
 && rm -rf /var/lib/apt/lists/*

# Install all PyPI deps + your local BasicSR
# The "-e ./BasicSR" line in requirements.txt makes pip install it
RUN pip install --no-cache-dir --prefix /install -r requirements.txt

# 2) Final runtime image
FROM python:3.10-slim
WORKDIR /app

# Bring in the pre‑installed packages
COPY --from=builder /install /usr/local

# Copy your app code
COPY app.py .
# If your code imports anything from BasicSR at runtime, you can copy it too:
COPY BasicSR/ ./BasicSR/

# Create directories for models & cache
RUN mkdir -p models cache

# Download your Real-ESRGAN weights at runtime (so that build never fails)
# (or you can bind‑mount them instead)
RUN wget -q -O models/RealESRGAN_x4plus.pth \
    https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus.pth

# Expose port & launch
EXPOSE 80
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
