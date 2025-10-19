#!/usr/bin/env bash
set -Eeuo pipefail

# --- Configuration ---
INPUT_DIR="data/img2img2vid"
OUTPUT_DIR="outputs/img2img2vid"

# --- Script Logic ---
echo "=> Starting Frame Interpolation batch processing..."
echo "   Input directory:  '${INPUT_DIR}'"
echo "   Output directory: '${OUTPUT_DIR}'"

# Check for input directory
if [ ! -d "${INPUT_DIR}" ] || [ -z "$(ls -A ${INPUT_DIR} 2>/dev/null)" ]; then
    echo "❌ ERROR: Input directory '${INPUT_DIR}' is empty or does not exist."
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "-> Searching for '_start' image files to process..."

# Loop through all files ending with _start.png/jpg/jpeg
for start_image in "${INPUT_DIR}"/*_start.{png,jpg,jpeg,PNG,JPG,JPEG}; do
    if [ -f "$start_image" ]; then

        # Construct filenames
        base_name=$(basename "$start_image" | sed -E 's/_start\.(png|jpg|jpeg|PNG|JPG|JPEG)$//')
        extension="${start_image##*.}"
        end_image="${INPUT_DIR}/${base_name}_end.${extension}"

        # Use a temporary directory for the intermediate frames
        temp_output_dir="${OUTPUT_DIR}/temp_${base_name}"
        final_video_path="${OUTPUT_DIR}/${base_name}.mp4"

        echo "-----------------------------------------------------"
        echo "-> Found pair: ${base_name}"
        echo "   Start image: $(basename "$start_image")"

        # Check if the end image exists
        if [ ! -f "$end_image" ]; then
            echo "   ⚠️  WARNING: Skipping. End image not found: $(basename "$end_image")"
            continue
        fi

        echo "   End image:   $(basename "$end_image")"
        echo "   Output video: $(basename "$final_video_path")"

        mkdir -p "$temp_output_dir"

        # Run the RIFE Python script, telling it to use the temp dir for frames
        # NOTE: The inference_video.py script needs to support an output directory parameter.
        # Assuming the script is modified or implicitly saves to the video's directory.
        # For now, we will create the video in the temp dir and then move it.
        temp_video_path="${temp_output_dir}/${base_name}.mp4"

        python3 -m src.rife_scripts.inference_video \
            --img_start "$start_image" \
            --img_end "$end_image" \
            --video_out "$temp_video_path"

        if [ $? -ne 0 ]; then
            echo "   ⚠️  WARNING: Processing failed for pair '${base_name}'"
        else
            # Move the final video from the temp dir to the final destination
            mv "$temp_video_path" "$final_video_path"
            echo "   ✅ Video interpolation complete."
        fi

        # Clean up the temporary directory with the frames
        rm -rf "$temp_output_dir"
        echo "   Temporary files cleaned up."
    fi
done

echo "====================================================="
echo "✅ Frame Interpolation batch processing finished."
