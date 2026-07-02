FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# System deps
RUN apt-get update && apt-get install -y \
    python3 python3-pip git wget curl \
    libgl1 libglib2.0-0 aria2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app

# Install PyTorch + ComfyUI deps
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Install ComfyUI Manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
    /app/custom_nodes/ComfyUI-Manager \
    && pip3 install --no-cache-dir \
    -r /app/custom_nodes/ComfyUI-Manager/requirements.txt

# Install huggingface_hub for model downloads
RUN pip3 install --no-cache-dir huggingface_hub hf_transfer

# Create model directories
RUN mkdir -p \
    /app/models/checkpoints \
    /app/models/vae \
    /app/models/loras \
    /app/models/controlnet \
    /app/models/diffusion_models \
    /app/models/clip \
    /app/models/unet

COPY entrypoint.sh /app/entrypoint.sh
COPY models.txt /app/models.txt
RUN chmod +x /app/entrypoint.sh

EXPOSE 8188

ENTRYPOINT ["/app/entrypoint.sh"]
