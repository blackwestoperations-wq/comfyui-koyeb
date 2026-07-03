FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# System dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app

# Install PyTorch
RUN python3 -m pip install --no-cache-dir \
    torch==2.3.1 \
    torchvision==0.18.1 \
    torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu118

# Install ComfyUI requirements
RUN python3 -m pip install --no-cache-dir -r /app/requirements.txt

# Install ComfyUI-Manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
    /app/custom_nodes/ComfyUI-Manager && \
    python3 -m pip install --no-cache-dir \
    -r /app/custom_nodes/ComfyUI-Manager/requirements.txt

# Create model folders
RUN mkdir -p \
    /app/models/checkpoints \
    /app/models/diffusion_models \
    /app/models/text_encoders \
    /app/models/vae \
    /app/models/loras \
    /app/models/controlnet \
    /app/models/clip \
    /app/output \
    /app/input

COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

EXPOSE 8188

ENTRYPOINT ["/app/entrypoint.sh"]
