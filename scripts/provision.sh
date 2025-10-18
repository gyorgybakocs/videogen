#!/usr/bin/env bash
set -Eeuo pipefail

# ---- Settings ----
MODELS_DIR="${1:-./models}"
SVD_REPO="stabilityai/stable-video-diffusion-img2vid-xt"
SVD_DIR="$MODELS_DIR/stable-video-diffusion"
MUSETALK_REPO="TMElyralab/MuseTalk"
MUSETALK_DIR="$MODELS_DIR/musetalk"

echo "Starting model downloads into '$MODELS_DIR'..."

# Ensure huggingface-cli exists
if ! command -v huggingface-cli >/dev/null 2>&1; then
  echo "ERROR: 'huggingface-cli' not found. Install with:"
  echo "  pip install -U huggingface_hub && huggingface-cli login"
  exit 1
fi

# Directory exists AND is non-empty
dir_exists_and_nonempty() {
  local d="$1"
  [[ -d "$d" ]] && [[ -n "$(ls -A "$d" 2>/dev/null || true)" ]]
}

download_hf_model() {
  local repo="$1"
  local target_dir="$2"
  if dir_exists_and_nonempty "$target_dir"; then
    echo "Model already present at '$target_dir'. Skipping."
  else
    echo "Downloading: $repo -> $target_dir"
    mkdir -p "$target_dir"
    hf download "$repo" \
      --local-dir "$target_dir" \
      --local-dir-use-symlinks False
  fi
}

# ---- Stable Video Diffusion ----
download_hf_model "$SVD_REPO" "$SVD_DIR"

# ---- MuseTalk ----
download_hf_model "$MUSETALK_REPO" "$MUSETALK_DIR"

echo "All models downloaded successfully."
