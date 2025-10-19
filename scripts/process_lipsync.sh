#!/usr/bin/env bash
set -Eeuo pipefail

# --- Configuration ---
INPUT_DIR="data/lipsync"
OUTPUT_DIR="outputs/lipsync"

# --- Script Logic ---
echo "=> Starting Lip-Sync batch processing based on file pairs..."
echo "   Input directory:  '${INPUT_DIR}'"
echo "   Output directory: '${OUTPUT_DIR}'"

# Check for input directory
if [ ! -d "${INPUT_DIR}" ] || [ -z "$(ls -A ${INPUT_DIR} 2>/dev/null)" ]; then
    echo "❌ ERROR: Input directory '${INPUT_DIR}' is empty or does not exist."
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "-> Searching for image files to process..."

# Loop through all image files (png, jpg, jpeg) in the input directory
for image_path in "${INPUT_DIR}"/*.{png,jpg,jpeg,PNG,JPG,JPEG}; do
    if [ -f "$image_path" ]; then

        # Get the base name of the file without extension
        base_name=$(basename "$image_path" | sed -E 's/\.(png|jpg|jpeg|PNG|JPG|JPEG)$//')

        # Construct other filenames
        audio_path="${INPUT_DIR}/${base_name}.wav"
        temp_output_dir="${OUTPUT_DIR}/temp_${base_name}"
        final_video_path="${OUTPUT_DIR}/${base_name}.mp4"

        echo "-----------------------------------------------------"
        echo "-> Found image: $(basename "$image_path")"

        # Check if the corresponding audio file exists
        if [ ! -f "$audio_path" ]; then
            echo "   ⚠️  WARNING: Skipping. Corresponding audio file not found: ${base_name}.wav"
            continue
        fi

        echo "   Found audio: $(basename "$audio_path")"
        echo "   Outputting to: '${final_video_path}'"

        mkdir -p "$temp_output_dir"

        # Run the MuseTalk Python script, outputting to the temp directory
        python3 -m src.musetalk_scripts.inference \
            --video_path "$image_path" \
            --audio_path "$audio_path" \
            --result_dir "$temp_output_dir"

        if [ $? -ne 0 ]; then
            echo "   ⚠️  WARNING: Processing failed for pair '${base_name}'"
        else
            # Find the generated video file and move it
            # The script saves it in a 'results' subdirectory.
            generated_video=$(find "${temp_output_dir}/results" -name "*.mp4" -type f | head -n 1)
            if [ -f "$generated_video" ]; then
                mv "$generated_video" "$final_video_path"
                echo "   ✅ Processing complete. Video saved."
            else
                echo "   ⚠️  WARNING: Could not find the generated video file in temp directory."
            fi
        fi

        # Clean up the temporary directory
        rm -rf "$temp_output_dir"
        echo "   Temporary files cleaned up."
    fi
done

echo "====================================================="
echo "✅ Lip-Sync batch processing finished."
