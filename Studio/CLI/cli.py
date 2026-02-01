import argparse
import json
import subprocess
import sys
import os
from pathlib import Path

# Add the API directory to Python path so we can import API modules
# This matches how Django runs the project (from API directory)
SCRIPT_DIR = Path(__file__).parent
STUDIO_DIR = SCRIPT_DIR.parent
API_DIR = STUDIO_DIR / "API"

# Add API directory to path (code_generation imports expect this)
sys.path.insert(0, str(API_DIR))

# Import using the same pattern as main.py
from process.process import process_model_bulk


def is_edam_file(path):
    """Check if a path is a .edam file."""
    # Handle both relative and absolute paths
    if os.path.isabs(path):
        return path.endswith('.edam') and os.path.isfile(path)
    else:
        # Try relative to current directory first, then relative to Studio directory
        if os.path.isfile(path):
            return path.endswith('.edam')
        studio_path = STUDIO_DIR / path
        return path.endswith('.edam') and studio_path.is_file()


def parse_edam_file(file_path):
    """
    Parse a .edam file using the Node.js parser and return the EDAM model.
    """
    try:
        # Get absolute path - handle both relative and absolute paths
        if os.path.isabs(file_path):
            abs_path = file_path
        else:
            # Try relative to current directory first
            if os.path.isfile(file_path):
                abs_path = os.path.abspath(file_path)
            else:
                # Try relative to Studio directory
                abs_path = str(STUDIO_DIR / file_path)
        
        if not os.path.isfile(abs_path):
            print(f"Error: .edam file not found: {file_path}")
            sys.exit(1)
        
        # Call the Node.js parser
        result = subprocess.run(
            ["node", str(SCRIPT_DIR / "edam_file_parser.js"), abs_path],
            capture_output=True,
            text=True,
            cwd=str(STUDIO_DIR)  # Run from Studio directory
        )
        
        if result.returncode != 0:
            print(f"Error parsing .edam file {file_path}:", result.stderr)
            sys.exit(1)
        
        # Parse the JSON output
        edam_model = json.loads(result.stdout)
        return edam_model
        
    except Exception as e:
        print(f"Error parsing .edam file {file_path}:", e)
        sys.exit(1)


def generate_edam_json(models, mode, config):
    """
    Calls the JavaScript script with the specified models, mode, and configuration
    to generate output.json.
    
    models can be a mix of:
    - Model names (strings) for predefined models
    - EDAM model objects (parsed from .edam files)
    """
    try:
        # Serialize config dictionary into JSON string
        config_json_str = json.dumps(config)
        
        # Serialize models array (can contain both strings and objects)
        models_json_str = json.dumps(models)

        # Construct the command
        # Pass models as JSON array, then mode, then config
        command = ["node", "./CLI/payload_generator.js", models_json_str, mode, config_json_str]
        print("Running command:", " ".join(command))

        # Run the JavaScript script from Studio directory
        result = subprocess.run(
            command, 
            capture_output=True, 
            text=True,
            cwd=str(STUDIO_DIR)  # Run from Studio directory
        )

        # Debug output
        #print("JavaScript Output:", result.stdout)

        # Handle errors
        if result.returncode != 0:
            print("Error in executing payload_generator.js:", result.stderr)
            sys.exit(1)

    except Exception as e:
        print("Error calling JavaScript script:", e)
        sys.exit(1)

def process_generated_json():
    """Reads output.json and processes it with process_model_bulk()."""
    try:
        # output.json is created in Studio directory
        output_json_path = STUDIO_DIR / "output.json"
        with open(output_json_path, "r") as f:
            raw_data = f.read()
        data = json.loads(raw_data)
        print("JSON successfully parsed!")
        process_model_bulk(data, with_response=False)
        print("CODE successfully generated!")
        # delete the output.json file
        os.remove(output_json_path)
    except json.JSONDecodeError as e:
        print("Error parsing JSON:", e)
    except FileNotFoundError:
        print("Error: output.json file not found. Ensure that payload_generator.js ran successfully.")

def main():
    parser = argparse.ArgumentParser(
        description="Generate and process EDAM JSON from models, mode, and config parameters."
    )
    parser.add_argument("models", metavar="MODEL", nargs="+", 
                       help="List of model names or paths to .edam files.")
    parser.add_argument("--mode", required=True, choices=["1", "2", "3", "4"], help="Mode of generation: 1 or 2 or 3.")

    # Configuration Parameters
    parser.add_argument("--probability_new_participant", type=float, default=0.35)
    parser.add_argument("--probability_right_participant", type=float, default=0.7)
    parser.add_argument("--probability_true_for_bool", type=float, default=0.5)
    parser.add_argument("--min_int_value", type=int, default=0)
    parser.add_argument("--max_int_value", type=int, default=100)
    parser.add_argument("--max_gen_array_size", type=int, default=10)
    parser.add_argument("--min_gen_string_length", type=int, default=5)
    parser.add_argument("--max_gen_string_length", type=int, default=10)
    parser.add_argument("--z3_check_enabled", action="store_true", default=True)
    parser.add_argument("--number_symbolic_traces", type=int, default=200)
    parser.add_argument("--number_transition_per_trace", type=int, default=10)
    parser.add_argument("--number_real_traces", type=int, default=5)
    parser.add_argument("--max_fail_try", type=int, default=2)
    parser.add_argument("--add_pi_to_test", action="store_true", default=False)
    parser.add_argument("--add_test_of_state", action="store_true", default=True)
    parser.add_argument("--add_test_of_variables", action="store_true", default=True)

    args = parser.parse_args()

    # Process models: check if any are .edam files and parse them
    processed_models = []
    for model_arg in args.models:
        if is_edam_file(model_arg):
            print(f"Parsing .edam file: {model_arg}")
            edam_model = parse_edam_file(model_arg)
            processed_models.append(edam_model)
            print(f"Successfully parsed EDAM model: {edam_model['name']}")
        else:
            # It's a model name, keep it as string
            processed_models.append(model_arg)

    # Build configuration dictionary to pass to the JS script
    config = {
        "probability_new_participant": args.probability_new_participant,
        "probability_right_participant": args.probability_right_participant,
        "probability_true_for_bool": args.probability_true_for_bool,
        "min_int_value": args.min_int_value,
        "max_int_value": args.max_int_value,
        "max_gen_array_size": args.max_gen_array_size,
        "min_gen_string_length": args.min_gen_string_length,
        "max_gen_string_length": args.max_gen_string_length,
        "z3_check_enabled": args.z3_check_enabled,
        "number_symbolic_traces": args.number_symbolic_traces,
        "number_transition_per_trace": args.number_transition_per_trace,
        "number_real_traces": args.number_real_traces,
        "max_fail_try": args.max_fail_try,
        "add_pi_to_test": args.add_pi_to_test,
        "add_test_of_state": args.add_test_of_state,
        "add_test_of_variables": args.add_test_of_variables
    }

    # Step 1: Call the JavaScript script
    generate_edam_json(processed_models, args.mode, config)

    # Step 2: Process the generated JSON
    process_generated_json()
    exit()

if __name__ == "__main__":
    main()
    