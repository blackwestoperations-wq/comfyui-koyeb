FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    git python3.11 python3.11-venv python3-pip \
    libgl1 libglib2.0-0 wget \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.11 /usr/bin/python3

WORKDIR /app

RUN git clone https://github.com/vladmandic/sdnext.git .

RUN python3 -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Install SD.Next's own deps ahead of time (bakes into image, faster cold start)
RUN python3 launch.py --skip-git --debug --test || true

# Install huggingface-hub CLI to pull weights at build time
RUN pip install -U "huggingface_hub[cli]"

# Pull Ideogram 4 weights into the image (choose ONE variant matching your GPU VRAM)
# fp8 for 48GB+ cards, nf4 for ~20GB cards
RUN huggingface-cli download ideogram-ai/ideogram-4-fp8 \
    --local-dir /app/models/checkpoints/ideogram-4-fp8

EXPOSE 7860

CMD ["python3", "launch.py", "--listen", "--port", "7860", "--use-cuda", "--api", \
     "--models-dir", "/app/models", "--ckpt-dir", "/app/models/checkpoints"]
