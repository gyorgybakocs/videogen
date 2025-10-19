#!/usr/bin/env bash
set -Eeuo pipefail

source ./scripts/login.sh

# --- Configuration ---
# Paths are relative to the project root, where this script is executed from (e.g., via 'make provision')
MODELS_DIR="./models"
SRC_DIR="./src"
TEMP_CLONE_DIR="temp_clone_$$" # Use a consistent temp dir name based on PID
# 1. Model Repositories (for Hugging Face)
SVD_MODEL_REPO="stabilityai/stable-video-diffusion-img2vid-xt"
MUSETALK_MODEL_REPO="TMElyralab/MuseTalk"
RIFE_MODEL_REPO="hzwer/Practical-RIFE"
# 2. Script Repositories (for Git)
SVD_SCRIPTS_REPO="https://github.com/Stability-AI/generative-models.git"
MUSETALK_SCRIPTS_REPO="https://github.com/TMElyralab/MuseTalk.git"
RIFE_SCRIPTS_REPO="https://github.com/hzwer/Practical-RIFE.git"

# --- Script Logic ---

echo "=> Starting provisioning process..."
mkdir -p "$MODELS_DIR"
mkdir -p "$SRC_DIR"

# Check for required commands
if ! command -v hf >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  echo "❌ ERROR: 'hf' and/or 'git' command is not installed. Please install them."
  echo "   'hf' is part of 'pip install -U huggingface_hub'"
  exit 1
fi

# --- Login to Hugging Face ---
echo "-----------------------------------------------------"
echo "-> Logging into Hugging Face..."
if [ -z "${HF_TOKEN-}" ]; then
  echo "   WARNING: HF_TOKEN is not set. Downloads may fail for gated models."
else
  export HF_TOKEN="${HF_TOKEN}"
  hf auth login --token "$HF_TOKEN" --add-to-git-credential
  git lfs install
  hf auth whoami
fi

# --- Helper Functions ---
dir_exists_and_nonempty() {
  local d="$1"
  [[ -d "$d" ]] && [[ -n "$(ls -A "$d" 2>/dev/null || true)" ]]
}

download_hf_model() {
  local repo="$1"
  local target_dir="$2"
  echo "-----------------------------------------------------"
  echo "-> Checking model: $repo"
  if dir_exists_and_nonempty "$target_dir"; then
    echo "   Model already exists at '$target_dir'. Skipping."
  else
    echo "   Downloading model to: $target_dir"
    hf download "$repo" --local-dir "$target_dir" --quiet
    echo "   Download complete."
  fi
}

download_git_scripts() {
    local repo_url="$1"
    local src_path_in_repo="$2"
    local dest_dir_name="$3"
    local final_dest_path="${SRC_DIR}/${dest_dir_name}"
    local temp_clone_dir="temp_clone_$$" # Use process ID for temp dir name

    echo "-----------------------------------------------------"
    echo "-> Checking scripts: ${repo_url}"

    if dir_exists_and_nonempty "${final_dest_path}"; then
        echo "   Scripts already exist at '${final_dest_path}'. Skipping."
    else
        echo "   Cloning repository to download scripts..."
        git clone --depth 1 "${repo_url}" "${temp_clone_dir}" > /dev/null 2>&1

        if [ "$src_path_in_repo" != "." ] && [ ! -d "${temp_clone_dir}/${src_path_in_repo}" ]; then
            echo "   ❌ ERROR: Source path '${src_path_in_repo}' not found in the cloned repository."
            rm -rf "${temp_clone_dir}"
            exit 1
        fi

        echo "   Extracting scripts to '${final_dest_path}'"

        if [ "${src_path_in_repo}" == "." ]; then
            # Special case for RIFE: move only the essential files
            mkdir -p "${final_dest_path}"
            mv "${temp_clone_dir}/model" "${final_dest_path}/"
            # Use a pattern to match all inference scripts
            mv "${temp_clone_dir}"/inference_*.py "${final_dest_path}/"
        else
            # Standard case: move a specific subdirectory
            mv "${temp_clone_dir}/${src_path_in_repo}" "${final_dest_path}"
        fi

        rm -rf "${temp_clone_dir}"
        echo "   Cleanup complete."
    fi
}

# --- Cleanup function ---
# This function will be called on script exit (normal or error)
cleanup() {
  echo "-> Running cleanup..."
  rm -rf "$TEMP_CLONE_DIR"
  echo "   Temporary directories removed."
}
# --- Trap Exit Signal ---
# Register the cleanup function to run when the script exits for any reason
trap cleanup EXIT

# --- PART 1: Download Models ---
echo
echo "====================================================="
echo "PART 1: DOWNLOADING AI MODELS"
echo "====================================================="
download_hf_model "$SVD_MODEL_REPO"    "${MODELS_DIR}/stable-video-diffusion"
download_hf_model "$MUSETALK_MODEL_REPO" "${MODELS_DIR}/musetalk"
download_hf_model "$RIFE_MODEL_REPO"   "${MODELS_DIR}/rife"

# --- PART 2: Download Scripts ---
echo
echo "====================================================="
echo "PART 2: DOWNLOADING EXECUTION SCRIPTS"
echo "====================================================="
# For SVD, we need the 'sampling' scripts from the generative-models repo
download_git_scripts "$SVD_SCRIPTS_REPO" "scripts/sampling" "svd_scripts"
# For MuseTalk, we need its own 'scripts' directory
download_git_scripts "$MUSETALK_SCRIPTS_REPO" "scripts" "musetalk_scripts"
# For RIFE, the main python files are in the root, so we extract '.'
download_git_scripts "$RIFE_SCRIPTS_REPO" "." "rife_scripts"


echo "-----------------------------------------------------"
echo "✅ Provisioning complete. All models and scripts are ready."
