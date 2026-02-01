#!/bin/bash

# Directory containing the ZIP files
ZIP_DIR="/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/py_server/py_server/code_zip/$1"
PROCESSED_DIR="/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/py_server/py_server/code_zip/processed"
RESUMO_BASE_DIR="/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/ReSuMo"
RESUMO_RESULT_DIR="$RESUMO_BASE_DIR/processed"

# Check if the ZIP directory exists
if [ ! -d "$ZIP_DIR" ]; then
    echo "Error: ZIP directory does not exist: $ZIP_DIR"
    exit 1
fi

# Ensure the processed directories exist
mkdir -p "$PROCESSED_DIR"
mkdir -p "$RESUMO_RESULT_DIR"

# Iterate over each .zip file in the directory
for zip_file in "$ZIP_DIR"/*.zip; do
    if [ -f "$zip_file" ]; then
        zip_filename=$(basename "$zip_file")
        base_dir="${ZIP_DIR}/${zip_filename%.zip}"
        sumo_dir="$RESUMO_BASE_DIR/.sumo_${zip_filename}"
        sumo_results="$sumo_dir/results/operators.xlsx"

        echo "Processing: $zip_filename"
        echo "Result should be in $sumo_results"

        # If the results file exists, skip processing
        if [ -f "$sumo_results" ]; then
            echo "Skipping processing for $zip_filename as results file exists."
            echo "Results directory: $sumo_dir"
        else
            
	    rm -rf $sumo_dir 
            echo "Deleting the sumoe dire: $sumo_dir"
        fi

        # Move only if the operation has been executed and results exist
        if [ -f "$sumo_results" ]; then
            echo "Results file found, moving files..."
            mv "$zip_file" "$PROCESSED_DIR/"
            mv "$base_dir" "$PROCESSED_DIR/"
            mv "$sumo_dir" "$RESUMO_RESULT_DIR/"
            echo "Moved $zip_filename, extracted folder, and results to processed directories."
        fi

        echo "--------------------------------------"
    fi
done

echo "All ZIP files processed successfully."

