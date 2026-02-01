import json
import os
import subprocess
from django.http import JsonResponse
from code_generation.process import CodeGenerationProcess
from code_generation.tests import TestGenerator
from code_generation.tests.parsers.trace_parser import TraceParser

# Directory setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # API directory
ROOT_DIR = os.path.dirname(BASE_DIR)  # Parent directory (root of the project)

# Load configuration from config.json
CONFIG_FILE = os.path.join(ROOT_DIR, "config.json")
CONFIG = {}
if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE, 'r') as f:
        CONFIG = json.load(f)

# Get directory paths from config or use defaults
GENERATED_CODE_DIR = CONFIG.get("generated_code", {}).get("default_directory", "Generated-code")
TEMP_DIR = os.path.join(BASE_DIR, "temp")
OUTPUT_DIR = os.path.join(TEMP_DIR, "output")
UPLOAD_DIR = os.path.join(ROOT_DIR, GENERATED_CODE_DIR)


# Ensure the temp and output directories exist
os.makedirs(TEMP_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(UPLOAD_DIR, exist_ok=True)


# Initialize code generation process
code_generation_process = CodeGenerationProcess(BASE_DIR, TEMP_DIR, OUTPUT_DIR, UPLOAD_DIR)

def process_models(body, with_response=True):
    """Process multiple models in bulk"""
    return code_generation_process.process_models(body, with_response) 


def process_model_bulk(body, with_response=True):
    """Process multiple models in bulk"""
    return code_generation_process.process_model_bulk(body, with_response) 



def process_execute_edam_trace(body):
    try:

        models = body["models"]
        trace_text = body.get("trace_text", "")
        dirs = code_generation_process.ocaml_generator.dirs
        ocaml_generator = code_generation_process.ocaml_generator

        test_gen = TestGenerator()
        edam_data, _ = test_gen.generate_edam_test_code(models)
        # Copy necessary files to the temporary directory
        ocaml_generator.copy_list_file_to_dir(dirs, "local_temp")
        
        unique_id = dirs["uid"]
        ocaml_file_path = os.path.join(dirs["local_temp"], f"trace_{unique_id}.ml")
        
        # Generate OCaml file
        with open(os.path.join(ocaml_generator.base_code_dir, "ocaml_trace_test_run_base_code.ml"), 'r') as base_file:
            trace_base_code = base_file.read()
        
        trace_base_code = trace_base_code.replace("{edams_code_here}", edam_data)

        trace = ';\n'.join(TraceParser.get_calls_list(trace_text))
        call_list = f"let calls_list = [\n{trace}\n]"
        trace_base_code = trace_base_code.replace("{call_list_here}", call_list)
        
        with open(ocaml_file_path, 'w') as f:
            f.write(trace_base_code + "\n")
        
        # Copy and modify the shell script
        cmd_script_name = f"cmd_test_run_{unique_id}.sh"
        cmd_script_path = os.path.join(TEMP_DIR, cmd_script_name)
        

        with open(os.path.join(ocaml_generator.base_code_dir, "cmd_test_run.sh"), 'r') as base_script:
            test_file_content = base_script.read()
        
        test_file_content = test_file_content.replace("{file_name}", f"trace_{unique_id}")
        
        with open(cmd_script_path, 'w') as f:
            f.write(test_file_content)
        
        # Execute the shell script and capture output
        trace_output_path = os.path.join(TEMP_DIR, f"trace_{unique_id}.txt")
        with open(trace_output_path, 'w') as output_file:
            subprocess.run(
                ["bash", cmd_script_path],
                stdout=output_file,
                stderr=subprocess.PIPE,
                check=True,
                cwd=dirs["local_temp"]
            )
        
        # Read and process the output file
        with open(trace_output_path, 'r') as input_file:
            result = input_file.read().split("________")[1].replace("\n", "<br/>")
        
        return JsonResponse({"success": "File generated successfully", "result": result}, status=200)
    
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON in request body."}, status=400)
    except Exception as e:
        return JsonResponse({"error": "An unexpected error occurred.", "details": str(e)}, status=500)
    finally: 
        # Clean up temporary files
        for root, dirs, files in os.walk(TEMP_DIR):
            for file in files:
                os.remove(os.path.join(root, file))
                continue
