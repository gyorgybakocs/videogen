#!/usr/bin/env bash
set -Eeuo pipefail

# --- Configuration ---
INPUT_DIR="data/img2vid"
OUTPUT_DIR="outputs/img2vid"
NUM_FRAMES="${1:-200}" # Default to 200 frames (approx. 8s at 25fps)

# --- Script Logic ---
echo "=> Starting Image-to-Video batch processing..."
echo "   Input directory:  '${INPUT_DIR}'"
echo "   Output directory: '${OUTPUT_DIR}'"
echo "   Frames to generate: ${NUM_FRAMES}"

mkdir -p "${OUTPUT_DIR}"

if [ -z "$(ls -A ${INPUT_DIR} 2>/dev/null)" ]; then
    echo "❌ ERROR: Input directory '${INPUT_DIR}' is empty or does not exist."
    exit 1
fi

echo "-> Found images to process. Starting generation..."

for image_file in "${INPUT_DIR}"/*.{png,jpg,jpeg,PNG,JPG,JPEG}; do
    if [ -f "$image_file" ]; then
        filename=$(basename -- "$image_file")
        filename_noext="${filename%.*}"

        # Temporary output directory for frames
        temp_output_dir="${OUTPUT_DIR}/temp_${filename_noext}"
        mkdir -p "$temp_output_dir"

        echo "-----------------------------------------------------"
        echo "-> Processing: ${filename}"
        echo "   Temporary frame directory: ${temp_output_dir}"

        # Run the SVD Python script
        python3 -m src.svd_scripts.simple_video_sample \
            --input_path "${image_file}" \
            --output_folder "${temp_output_dir}" \
            --num_frames "${NUM_FRAMES}" \
            --version "svd_xt" \
            --device "cuda"

        if [ $? -ne 0 ]; then
            echo "   ⚠️  WARNING: Processing failed for ${filename}"
            rm -rf "$temp_output_dir" # Clean up temp dir on failure
            continue # Move to the next image
        fi

        # Find the generated video file (assuming there's only one mp4)
        generated_video=$(find "$temp_output_dir" -name "*.mp4" -print -quit)

        if [ -n "$generated_video" ]; then
            # Move the final video to the main output directory
            mv "$generated_video" "${OUTPUT_DIR}/${filename_noext}.mp4"
            echo "   ✅ Video created: ${OUTPUT_DIR}/${filename_noext}.mp4"
        else
            echo "   ⚠️  WARNING: No MP4 file found after processing ${filename}"
        fi

        # Clean up the temporary directory with the frames
        rm -rf "$temp_output_dir"
        echo "   Temporary files cleaned up."
    fi
done

echo "====================================================="
echo "✅ Batch processing finished."
