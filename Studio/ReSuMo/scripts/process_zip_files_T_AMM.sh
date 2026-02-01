#!/bin/bash

# Directory containing the ZIP files
ZIP_DIR="/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/py_server/py_server/code_zip/Test_T_A"  

# Check if the ZIP directory exists
if [ ! -d "$ZIP_DIR" ]; then
    echo "Error: ZIP directory does not exist: $ZIP_DIR"
    exit 1
fi

# Iterate over each .zip file in the directory
for zip_file in "$ZIP_DIR"/*.zip; do
    if [ -f "$zip_file" ]; then
        zip_filename=$(basename "$zip_file")
        base_dir="${ZIP_DIR}/${zip_filename%.zip}"
        echo "Processing: $zip_filename"

        # If a directory with the name of the zip file does not exist, unzip the file
        if [ ! -d "$base_dir" ]; then
            #mkdir -p "$base_dir"
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

        # Replace the content of config_temp.json
        CONFIG_FILE="/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/ReSuMo/src/config_temp.json"
        cat > "$CONFIG_FILE" <<EOL
{
    "targetDir": "$base_dir",
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

        cd "/home/elvis/Documents/GitHub/DAFSM-Updated/solidity_code_gen/ReSuMo"
        
        # Run npm commands sequentially
        echo "Running: npm run sumo cleanSumo"
        npm run sumo cleanSumo
        if [ $? -ne 0 ]; then
            echo "Error running 'npm run sumo cleanSumo' for $zip_filename, skipping to next file."
            continue
        fi

        echo "Running: npm run sumo test"
        npm run sumo test
        if [ $? -ne 0 ]; then
            echo "Error running 'npm run sumo test' for $zip_filename, skipping to next file."
            continue
        fi

        echo "Completed processing: $zip_filename"
        echo "--------------------------------------"
    fi
done

echo "All ZIP files processed successfully."
