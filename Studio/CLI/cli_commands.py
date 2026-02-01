#!/usr/bin/env python3
"""
CLI Commands Handler for Edam Studio
Supports:
- .generate edams -> calls cli.py
- .run resumo <zip_file> -> runs ReSuMo on a specific zip file
- .run test <zip_file> <command> -> runs test/coverage on a zip file
"""

import argparse
import os
import sys
import subprocess
import json
import zipfile
import shutil
from pathlib import Path


# Get the base directory (Studio directory)
BASE_DIR = Path(__file__).parent.parent
ROOT_DIR = BASE_DIR.parent

# Load configuration
CONFIG_FILE = BASE_DIR / "config.json"
CONFIG = {}
if CONFIG_FILE.exists():
    with open(CONFIG_FILE, 'r') as f:
        CONFIG = json.load(f)

# Get paths from config
GENERATED_CODE_DIR = BASE_DIR / CONFIG.get("generated_code", {}).get("default_directory", "Generated-code")
RESUMO_BASE_DIR = Path(CONFIG.get("sumo", {}).get("absolute_sumo_dir", BASE_DIR / "ReSuMo"))
RESUMO_CONFIG_FILE = RESUMO_BASE_DIR / "src" / "config_temp.json"


def generate_edams(args):
    """Call cli.py to generate EDAMs"""
    cli_path = BASE_DIR / "CLI" / "cli.py"
    
    # Build command arguments
    cmd = [sys.executable, str(cli_path)] + args.models
    
    # Add mode
    cmd.extend(["--mode", args.mode])
    
    # Add optional config parameters
    if hasattr(args, 'probability_new_participant'):
        cmd.extend(["--probability_new_participant", str(args.probability_new_participant)])
    if hasattr(args, 'probability_right_participant'):
        cmd.extend(["--probability_right_participant", str(args.probability_right_participant)])
    if hasattr(args, 'probability_true_for_bool'):
        cmd.extend(["--probability_true_for_bool", str(args.probability_true_for_bool)])
    if hasattr(args, 'min_int_value'):
        cmd.extend(["--min_int_value", str(args.min_int_value)])
    if hasattr(args, 'max_int_value'):
        cmd.extend(["--max_int_value", str(args.max_int_value)])
    if hasattr(args, 'max_gen_array_size'):
        cmd.extend(["--max_gen_array_size", str(args.max_gen_array_size)])
    if hasattr(args, 'min_gen_string_length'):
        cmd.extend(["--min_gen_string_length", str(args.min_gen_string_length)])
    if hasattr(args, 'max_gen_string_length'):
        cmd.extend(["--max_gen_string_length", str(args.max_gen_string_length)])
    if hasattr(args, 'z3_check_enabled') and args.z3_check_enabled:
        cmd.append("--z3_check_enabled")
    if hasattr(args, 'number_symbolic_traces'):
        cmd.extend(["--number_symbolic_traces", str(args.number_symbolic_traces)])
    if hasattr(args, 'number_transition_per_trace'):
        cmd.extend(["--number_transition_per_trace", str(args.number_transition_per_trace)])
    if hasattr(args, 'number_real_traces'):
        cmd.extend(["--number_real_traces", str(args.number_real_traces)])
    if hasattr(args, 'max_fail_try'):
        cmd.extend(["--max_fail_try", str(args.max_fail_try)])
    if hasattr(args, 'add_pi_to_test') and args.add_pi_to_test:
        cmd.append("--add_pi_to_test")
    if hasattr(args, 'add_test_of_state') and args.add_test_of_state:
        cmd.append("--add_test_of_state")
    if hasattr(args, 'add_test_of_variables') and args.add_test_of_variables:
        cmd.append("--add_test_of_variables")
    
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=BASE_DIR)
    return result.returncode


def run_resumo(zip_filename):
    """Run ReSuMo on a specific zip file from Generated-code directory"""
    zip_path = GENERATED_CODE_DIR / zip_filename
    
    if not zip_path.exists():
        print(f"Error: ZIP file not found: {zip_path}")
        return 1
    
    if not zip_path.suffix == '.zip':
        print(f"Error: File is not a ZIP file: {zip_filename}")
        return 1
    
    # Extract to a directory next to the zip file (similar to original script)
    base_dir = GENERATED_CODE_DIR / zip_path.stem
    sumo_dir = base_dir / f".sumo_{zip_filename}"
    sumo_results = sumo_dir / "results" / "operators.xlsx"
    
    print(f"Processing: {zip_filename}")
    
    # Check if results already exist
    if sumo_results.exists():
        print(f"Skipping processing for {zip_filename} as results file exists.")
        print(f"Results directory: {sumo_dir}")
        return 0
    
    # Remove existing directory if it exists to avoid changes from previous runs
    if base_dir.exists():
        print(f"Removing existing directory: {base_dir}")
        shutil.rmtree(base_dir)
    
    # Extract zip file
    print(f"Extracting {zip_filename} to {base_dir}")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(base_dir)
    
    # Run npm install
    print(f"Running npm install in {base_dir}")
    result = subprocess.run(["npm", "install"], cwd=base_dir, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running 'npm install': {result.stderr}")
        return 1
    
    # Update config_temp.json with absolute paths
    print(f"Updating config_temp.json")
    config_data = {
        "targetDir": str(base_dir.absolute()),
        "excludedFunctions": ["roleSatisf", "_roles", "min", "sum"],
        "contractsDir": str((base_dir / "contracts").absolute()),
        "testDir": str((base_dir / "test").absolute()),
        "buildDir": str((base_dir / "builds").absolute()),
        "sumoDir": f".sumo_{zip_filename}",
        "resultsDir": f".sumo_{zip_filename}/results",
        "artifactsDir": f".sumo_{zip_filename}/artifacts",
        "baselineDir": f".sumo_{zip_filename}/baseline"
    }
    
    RESUMO_CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(RESUMO_CONFIG_FILE, 'w') as f:
        json.dump(config_data, f, indent=4)
    
    # Run ReSuMo commands
    print(f"Running ReSuMo in {RESUMO_BASE_DIR}")
    
    # Clean sumo
    print("Running: npm run sumo cleanSumo")
    result = subprocess.run(["npm", "run", "sumo", "cleanSumo"], 
                          cwd=RESUMO_BASE_DIR, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running 'npm run sumo cleanSumo': {result.stderr}")
        return 1
    
    # Run sumo test
    print("Running: npm run sumo test")
    result = subprocess.run(["npm", "run", "sumo", "test"], 
                          cwd=RESUMO_BASE_DIR, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running 'npm run sumo test': {result.stderr}")
        return 1
    
    # Check if results were generated
    if sumo_results.exists():
        print(f"ReSuMo processing completed successfully!")
        print(f"Results available at: {sumo_results}")
    else:
        print("Warning: Results file not found after processing")
    
    return 0


def run_test(zip_filename, command="test"):
    """Run test or coverage on a zip file from Generated-code directory"""
    zip_path = GENERATED_CODE_DIR / zip_filename
    
    if not zip_path.exists():
        print(f"Error: ZIP file not found: {zip_path}")
        return 1
    
    if not zip_path.suffix == '.zip':
        print(f"Error: File is not a ZIP file: {zip_filename}")
        return 1
    
    # Extract to a directory next to the zip file (same directory as zip)
    base_dir = GENERATED_CODE_DIR / zip_path.stem
    
    print(f"Processing: {zip_filename}")
    
    # Remove existing directory if it exists to avoid conflicts
    if base_dir.exists():
        print(f"Removing existing directory: {base_dir}")
        shutil.rmtree(base_dir)
    
    print(f"Extracting {zip_filename} to {base_dir}")
    
    # Extract zip file
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(base_dir)
    
    # Run npm install
    print(f"Running npm install in {base_dir}")
    result = subprocess.run(["npm", "install"], cwd=base_dir, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running 'npm install': {result.stderr}")
        return 1
    
    # Run the requested hardhat command
    if command == "test":
        hardhat_cmd = ["npx", "hardhat", "test"]
    elif command == "coverage":
        hardhat_cmd = ["npx", "hardhat", "coverage"]
    else:
        # Allow custom commands like "test --grep 'specific test'"
        hardhat_cmd = ["npx", "hardhat"] + command.split()
    
    print(f"Running: {' '.join(hardhat_cmd)} in {base_dir}")
    result = subprocess.run(hardhat_cmd, cwd=base_dir)
    
    return result.returncode


def main():
    parser = argparse.ArgumentParser(
        description="Edam Studio CLI Commands",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  .generate edams Model1 Model2 --mode 1
  .run resumo myfile.zip
  .run test myfile.zip test
  .run test myfile.zip coverage
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Generate command
    gen_parser = subparsers.add_parser('generate', help='Generate EDAMs')
    gen_parser.add_argument('action', choices=['edams'], help='Action: edams')
    gen_parser.add_argument('models', nargs='+', help='List of model names')
    gen_parser.add_argument('--mode', required=True, choices=['1', '2', '3', '4'], 
                           help='Mode of generation')
    
    # Add all the config parameters from cli.py
    gen_parser.add_argument('--probability_new_participant', type=float, default=0.35)
    gen_parser.add_argument('--probability_right_participant', type=float, default=0.7)
    gen_parser.add_argument('--probability_true_for_bool', type=float, default=0.5)
    gen_parser.add_argument('--min_int_value', type=int, default=0)
    gen_parser.add_argument('--max_int_value', type=int, default=100)
    gen_parser.add_argument('--max_gen_array_size', type=int, default=10)
    gen_parser.add_argument('--min_gen_string_length', type=int, default=5)
    gen_parser.add_argument('--max_gen_string_length', type=int, default=10)
    gen_parser.add_argument('--z3_check_enabled', action='store_true', default=True)
    gen_parser.add_argument('--number_symbolic_traces', type=int, default=200)
    gen_parser.add_argument('--number_transition_per_trace', type=int, default=10)
    gen_parser.add_argument('--number_real_traces', type=int, default=5)
    gen_parser.add_argument('--max_fail_try', type=int, default=2)
    gen_parser.add_argument('--add_pi_to_test', action='store_true', default=False)
    gen_parser.add_argument('--add_test_of_state', action='store_true', default=True)
    gen_parser.add_argument('--add_test_of_variables', action='store_true', default=True)
    
    # Run command
    run_parser = subparsers.add_parser('run', help='Run operations on zip files')
    run_subparsers = run_parser.add_subparsers(dest='run_action', help='Run action')
    
    # Resumo subcommand
    resumo_parser = run_subparsers.add_parser('resumo', help='Run ReSuMo on a zip file')
    resumo_parser.add_argument('zip_file', help='ZIP file name in Generated-code directory')
    
    # Test subcommand
    test_parser = run_subparsers.add_parser('test', help='Run tests on a zip file')
    test_parser.add_argument('zip_file', help='ZIP file name in Generated-code directory')
    test_parser.add_argument('test_command', nargs='?', default='test', 
                            help='Command to run: test, coverage, or custom hardhat command')
    
    args = parser.parse_args()
    
    if args.command == 'generate':
        if args.action == 'edams':
            return generate_edams(args)
    elif args.command == 'run':
        if args.run_action == 'resumo':
            return run_resumo(args.zip_file)
        elif args.run_action == 'test':
            return run_test(args.zip_file, args.test_command)
    
    parser.print_help()
    return 1


if __name__ == '__main__':
    sys.exit(main())
