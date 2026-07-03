# Latest stable PyTorch runtime (includes CUDA and cuDNN)
FROM pytorch/pytorch:2.9.0-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

# --------------------------------------------------------------------
# System packages
# --------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------
# Clone latest ComfyUI
# --------------------------------------------------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# --------------------------------------------------------------------
# Upgrade pip
# --------------------------------------------------------------------
RUN python -m pip install --upgrade pip setuptools wheel

# --------------------------------------------------------------------
# Install ComfyUI requirements
# --------------------------------------------------------------------
RUN pip install -r requirements.txt

# --------------------------------------------------------------------
# Install ComfyUI Manager
# --------------------------------------------------------------------
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
    custom_nodes/ComfyUI-Manager

RUN pip install \
    -r custom_nodes/ComfyUI-Manager/requirements.txt

# --------------------------------------------------------------------
# Model directories
# --------------------------------------------------------------------
RUN mkdir -p \
    models/checkpoints \
    models/diffusion_models \
    models/clip \
    models/clip_vision \
    models/controlnet \
    models/embeddings \
    models/gligen \
    models/hypernetworks \
    models/loras \
    models/style_models \
    models/text_encoders \
    models/unet \
    models/upscale_models \
    models/vae \
    models/vae_approx \
    input \
    output \
    user

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]
