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
        sumo_dir="$base_dir/.sumo_${zip_filename}"
        sumo_results="$sumo_dir/results/operators.xlsx"

        echo "Processing: $zip_filename"

        # If the results file exists, skip processing
        if [ -f "$sumo_results" ]; then
            echo "Skipping processing for $zip_filename as results file exists."
            echo "Results directory: $sumo_dir"
        else
            # If the directory for the zip file does not exist, unzip it
            if [ ! -d "$base_dir" ]; then
                unzip "$zip_file" -d "$base_dir"
                echo "Unzipped $zip_filename to $base_dir"
            else 
                #delete it to avoid changes made during previous mutation
            	rm -rf "$base_dir"
            	unzip "$zip_file" -d "$base_dir"
                echo "Unzipped $zip_filename to $base_dir"
            fi

            # Run npm install in that directory
            cd "$base_dir" || { echo "Failed to change directory to $base_dir"; continue; }
            npm install
            if [ $? -ne 0 ]; then
                echo "Error running 'npm install' for $zip_filename, skipping to next file."
                continue
            fi

            #npx hardhat test > result_test.txt

            # Replace the content of config_temp.json
            CONFIG_FILE="/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/ReSuMo/src/config_temp.json"
            cat > "$CONFIG_FILE" <<EOL
{
    "targetDir": "$base_dir",
    "excludedFunctions": ["roleSatisf", "_roles"],
    "contractsDir": "$base_dir/contracts",
    "testDir": "$base_dir/test",
    "buildDir": "$base_dir/builds",
    "sumoDir": ".sumo_${zip_filename}",
    "resultsDir": ".sumo_${zip_filename}/results",
    "artifactsDir": ".sumo_${zip_filename}/artifacts",
    "baselineDir": ".sumo_${zip_filename}/baseline"
}
EOL
            echo "Updated config_temp.json for $zip_filename"

            cd "$RESUMO_BASE_DIR"
            
            # Run npm commands sequentially
            echo "Running: npm run sumo cleanSumo"
            npm run sumo cleanSumo
            if [ $? -ne 0 ]; then
                echo "Error running 'npm run sumo cleanSumo' for $zip_filename, skipping to next file."
                continue
            fi

            echo "Running: npm run sumo test"
            npm run sumo mutate
            if [ $? -ne 0 ]; then
                echo "Error running 'npm run sumo test' for $zip_filename, skipping to next file."
                continue
            fi

            echo "Completed processing: $zip_filename"
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

