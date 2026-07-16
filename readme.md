# ComfyUI on Koyeb

ComfyUI with **ComfyUI Manager** pre-installed and `security_level = weak` so
you can install custom nodes from Git URLs directly in the UI.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the image (CUDA 12.1 + PyTorch + ComfyUI + Manager) |
| `start.sh` | Entrypoint — respects Koyeb's `$PORT` env var |
| `manager_config.ini` | Sets `security_level = weak` + enables Git URL installs |
| `koyeb.yaml` | Optional declarative Koyeb service definition |

---

## Deploy via Koyeb Console (recommended)

### 1. Push this repo to GitHub
```bash
git init
git add .
git commit -m "ComfyUI Koyeb deployment"
git remote add origin https://github.com/YOUR_ORG/YOUR_REPO.git
git push -u origin main
```

### 2. Create a new Koyeb service
1. Go to [app.koyeb.com](https://app.koyeb.com) → **Create Service**
2. Source → **GitHub** → select your repo and `main` branch
3. Builder → **Dockerfile** (auto-detected)
4. Instance type → **GPU** (e.g. `gpu-nvidia-rtx4000-sff`)
5. Port → `8188` / Protocol → `HTTP`
6. Add environment variable:
   - `ALLOW_GIT_URL_INSTALL` = `1`
7. Health check path → `/` with **60 s initial delay**
8. Click **Deploy**

### 3. Access ComfyUI
Koyeb provides a public HTTPS URL once the service is healthy (usually 3–5 min
on first build).

---

## Deploy via Koyeb CLI

```bash
# Install CLI
curl -fsSL https://github.com/koyeb/koyeb-cli/releases/latest/download/koyeb_linux_amd64.tar.gz | tar xz
sudo mv koyeb /usr/local/bin/

# Login
koyeb login

# Deploy (edit koyeb.yaml first to set your git repo URL)
koyeb deploy --config koyeb.yaml
```

---

## Security note

`security_level = weak` + `ALLOW_GIT_URL_INSTALL=1` let the Manager install
**any** custom node from a URL. This is fine for a private/personal deployment.
If you expose ComfyUI publicly, consider adding authentication (e.g. Koyeb's
built-in basic auth or an upstream proxy).

---

## Adding models

Models are **not** baked into the image (they're too large). Options:

### A) Mount a persistent volume (recommended)
Koyeb → Service → **Volumes** → attach to `/app/ComfyUI/models`

### B) Download at startup via env var + script
Add a `download_models.sh` step in `start.sh`:
```bash
wget -q -O /app/ComfyUI/models/checkpoints/model.safetensors "$MODEL_URL"
```

### C) Use CivitAI/HuggingFace downloader via ComfyUI Manager
Once running, open the Manager panel → **Install Models**.
