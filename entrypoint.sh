#!/bin/bash
set -e

echo "========================================"
echo "  ComfyUI + Manager  |  Koyeb Startup"
echo "========================================"

# Speed up HuggingFace downloads via hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1

# ── Model downloader ─────────────────────────────────────────────────────────
# Downloads a file from URL to an absolute DEST path.
# Skips if the file already exists (won't help with autoscaling cold starts,
# but avoids re-downloading if the container is merely restarted).
download_model() {
  local URL="$1"
  local DEST="$2"

  if [ -f "$DEST" ]; then
    echo "[SKIP] Already present: $(basename "$DEST")"
    return 0
  fi

  mkdir -p "$(dirname "$DEST")"
  echo "[DOWN] $(basename "$DEST")"
  echo "       → $DEST"

  # Try wget with auth header; fall back without if no HF_TOKEN set
  if [ -n "$HF_TOKEN" ]; then
    wget -q --show-progress \
         --header="Authorization: Bearer ${HF_TOKEN}" \
         -O "$DEST" "$URL"
  else
    wget -q --show-progress \
         -O "$DEST" "$URL"
  fi

  echo "[DONE] $(basename "$DEST")"
}

# ── Read and process models.txt ───────────────────────────────────────────────
# Format of each line:  URL  ABSOLUTE_DEST_PATH
# Lines starting with # are comments; blank lines are ignored.

echo ""
echo "--- Downloading models ---"
while IFS=' ' read -r URL DEST || [ -n "$URL" ]; do
  # Skip blank lines and comments
  [[ -z "$URL" || "$URL" == \#* ]] && continue
  download_model "$URL" "$DEST"
done < /app/models.txt

echo ""
echo "--- All models ready ---"
echo ""

# ── Launch ComfyUI ────────────────────────────────────────────────────────────
echo "Starting ComfyUI on port 8188..."
exec python3 /app/main.py \
  --listen 0.0.0.0 \
  --port 8188 \
  --enable-cors-header "*"
