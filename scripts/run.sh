#!/bin/bash
set -e

INPUT_IMAGE="data/marathon.png"
OUTPUT_FOLDER="outputs/"

echo "Process started from '$INPUT_IMAGE' image..."

python3 -m scripts.sampling.simple_video_sample \
    --input_path $INPUT_IMAGE \
    --output_folder $OUTPUT_FOLDER \
    --version "svd_xt" \
    --decoding_t 3 \
    --device "cuda"

echo "Process finished. Result is in the '$OUTPUT_FOLDER' folder."