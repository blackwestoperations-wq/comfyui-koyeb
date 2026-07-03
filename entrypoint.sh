#!/usr/bin/env bash
set -e

echo "================================================="
echo "      ComfyUI + DigitalOcean Spaces Startup"
echo "================================================="

WORKSPACE=/workspace
REMOTE=dospaces

echo ""
echo "Python: $(python --version)"
echo ""

# ------------------------------------------------------------------
# GPU Information
# ------------------------------------------------------------------

python - <<EOF
import torch

print("PyTorch:", torch.__version__)
print("CUDA:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
    print("VRAM:",
          round(torch.cuda.get_device_properties(0).total_memory/1024**3,1),
          "GB")
EOF

# ------------------------------------------------------------------
# Configure rclone
# ------------------------------------------------------------------

mkdir -p /root/.config/rclone

cat >/root/.config/rclone/rclone.conf <<EOF
[$REMOTE]
type = s3
provider = DigitalOcean
env_auth = false
access_key_id = ${AWS_ACCESS_KEY_ID}
secret_access_key = ${AWS_SECRET_ACCESS_KEY}
endpoint = ${SPACES_ENDPOINT}
region = ${AWS_DEFAULT_REGION}
acl = private
EOF

echo ""
echo "Connecting to DigitalOcean Spaces..."

# ------------------------------------------------------------------
# Sync DOWN from Spaces
# ------------------------------------------------------------------

if rclone lsd ${REMOTE}:${SPACES_BUCKET}; then
    echo ""
    echo "Syncing workspace from DigitalOcean Spaces..."

    rclone sync \
        ${REMOTE}:${SPACES_BUCKET} \
        ${WORKSPACE} \
        --fast-list \
        --transfers 8 \
        --checkers 16 \
        --progress
else
    echo ""
    echo "Bucket is empty."
fi

# ------------------------------------------------------------------
# Make sure folders exist
# ------------------------------------------------------------------

mkdir -p \
    ${WORKSPACE}/models \
    ${WORKSPACE}/custom_nodes \
    ${WORKSPACE}/input \
    ${WORKSPACE}/output \
    ${WORKSPACE}/user \
    ${WORKSPACE}/workflows \
    ${WORKSPACE}/configs

# ------------------------------------------------------------------
# Copy persistent config
# ------------------------------------------------------------------

if [ -f ${WORKSPACE}/configs/config.ini ]; then
    mkdir -p /app/user/__manager
    cp ${WORKSPACE}/configs/config.ini \
       /app/user/__manager/config.ini
fi

# ------------------------------------------------------------------
# Copy persistent custom nodes
# ------------------------------------------------------------------

if [ -d ${WORKSPACE}/custom_nodes ]; then
    rsync -a \
        ${WORKSPACE}/custom_nodes/ \
        /app/custom_nodes/
fi

# ------------------------------------------------------------------
# Background sync every 60 seconds
# ------------------------------------------------------------------

(
while true
do

    sleep 60

    rclone sync \
        ${WORKSPACE} \
        ${REMOTE}:${SPACES_BUCKET} \
        --fast-list \
        --transfers 8 \
        --checkers 16

done
) &

echo ""
echo "Starting ComfyUI..."
echo ""

exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --extra-model-paths-config ${WORKSPACE}/extra_model_paths.yaml
