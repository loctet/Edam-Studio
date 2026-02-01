import os
import re
import shutil

# Regular expression pattern to extract components from the folder name
FOLDER_PATTERN = re.compile(r'^\.sumo_(.*?)_([\d]+)_([\d\.]+)_(pi|no_pi)_[a-f0-9-]+_([a-f0-9-]+)\.zip$')

# Get the current directory
current_directory = os.getcwd()

# Iterate through all items in the current directory
for folder_name in os.listdir(current_directory):  
    folder_path = os.path.join(current_directory, folder_name)
    
    # Check if the item is a directory
    if os.path.isdir(folder_path):  
        match = FOLDER_PATTERN.match(folder_name)
        if match:
            asset_name, num_test, value, pi_status, time = match.groups()
            
            # Construct paths
            results_folder = os.path.join(folder_path, 'results')
            old_file_path = os.path.join(results_folder, 'operators.xlsx')
            new_file_name = f"{asset_name}_{num_test}_{value}_{pi_status}_{time}.xlsx"
            new_file_path = os.path.join(current_directory, new_file_name)
            
            # Copy the file if it exists
            if os.path.exists(old_file_path):
                shutil.copy2(old_file_path, new_file_path)
                print(f"Copied: {old_file_path} -> {new_file_path}")
            else:
                print(f"File not found: {old_file_path}")

