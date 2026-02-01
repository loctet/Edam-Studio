import argparse
import json
import subprocess
import sys
from API.process.process import process_model_bulk


def generate_edam_json(models, mode, config):
    """
    Calls the JavaScript script with the specified models, mode, and configuration
    to generate output.json.
    """
    try:
        # Serialize config dictionary into JSON string
        config_json_str = json.dumps(config)

        # Construct the command
        command = ["node", "./CLI/payload_generator.js"] + models + [mode, config_json_str]
        print("Running command:", " ".join(command))

        # Run the JavaScript script
        result = subprocess.run(command, capture_output=True, text=True)

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
        with open("output.json", "r") as f:
            raw_data = f.read()
        data = json.loads(raw_data)
        print("JSON successfully parsed!")
        process_model_bulk(data, with_response=False)
        print("CODE successfully generated!")
    except json.JSONDecodeError as e:
        print("Error parsing JSON:", e)
    except FileNotFoundError:
        print("Error: output.json file not found. Ensure that payload_generator.js ran successfully.")

def main():
    parser = argparse.ArgumentParser(
        description="Generate and process EDAM JSON from models, mode, and config parameters."
    )
    parser.add_argument("models", metavar="MODEL", nargs="+", help="List of model names.")
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
    generate_edam_json(args.models, args.mode, config)

    # Step 2: Process the generated JSON
    process_generated_json()
    exit()

if __name__ == "__main__":
    main()
    