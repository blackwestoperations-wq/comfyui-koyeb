# ComfyUI on Koyeb GPU
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PORT=8188

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3-pip \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Clone ComfyUI
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Install PyTorch with CUDA 12.4
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Install ComfyUI requirements
RUN pip install --no-cache-dir -r requirements.txt

# Create model directories
RUN mkdir -p models/checkpoints models/vae models/clip models/controlnet \
    models/loras models/upscale_models models/unet

# Expose ComfyUI's default port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8188/')" || exit 1

# Start ComfyUI (listen on all interfaces)
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
