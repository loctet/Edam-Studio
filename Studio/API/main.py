import os
import json
import zipfile
import subprocess
import time

from django.http import JsonResponse, FileResponse # type: ignore
from django.views.decorators.csrf import csrf_exempt # type: ignore
from django.conf import settings # type: ignore
from django.core.files.storage import FileSystemStorage # type: ignore


from process.process import process_models, code_generation_process, process_execute_edam_trace
from objects.EdamClass import EDAM
from objects.TransitionClass import Transition
from objects.Expressions import *
from code_generation.ocaml.generator import OCamlCodeGenerator

@csrf_exempt
def convert_bulk(request):
    if request.method != 'POST':
        return JsonResponse({"error": "Only POST method is allowed."}, status=405)
    body = json.loads(request.body)
    if not isinstance(body.get("models"), list):
        return JsonResponse({"error": "Expected an array of EDAMs."}, status=400)
    
    # Get target language from request body, default to "solidity"
    target_language = body.get("target_language", "solidity")
    
    return process_models(body)

@csrf_exempt
def execute_edam_trace(request):
    try:
        
        if request.method != 'POST':
            return JsonResponse({"error": "Only POST method is allowed."}, status=405)

        body = json.loads(request.body)

        if not isinstance(body.get("models"), list):
            return JsonResponse({"error": "Expected an array of EDAMs."}, status=400)

        return process_execute_edam_trace(body)
    except Exception as e :
        print(e)
       

def download_file(request, file_name):
    """
    Route to handle file download.
    """
    try:
        file_path = os.path.join(code_generation_process.upload_dir, file_name)
        if not os.path.exists(file_path):
            return JsonResponse({"error": "File not found"}, status=404)

        # Serve the file as a download
        response = FileResponse(open(file_path, 'rb'), as_attachment=True, filename=file_name)
        return response

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


def run_test_file(request, file_name):
    """
    Route to handle file download.
    Checks if the folder exists. If not, it unzips the file and runs the `./run` command in the folder.
    """
    try:
        # Define the file path and target folder
        file_path = os.path.join(code_generation_process.upload_dir, file_name)
        folder_path = os.path.join(code_generation_process.upload_dir, "".join(file_name.split('.')[::1]))  # Assuming zip file

        # Check if file exists
        if not os.path.exists(file_path):
            return JsonResponse({"error": "File not found"}, status=404)

        # Check if the folder exists
        if not os.path.exists(folder_path):
            # Unzip the file if the folder does not exist
            with zipfile.ZipFile(file_path, 'r') as zip_ref:
                zip_ref.extractall(folder_path)

        # Ensure the 'run' file is executable
        run_file_path = os.path.join(folder_path, 'run')
        if not os.access(run_file_path, os.X_OK):
            os.chmod(run_file_path, 0o755)

        # Run `npm install` to install dependencies
        npm_result = subprocess.run('npm install', cwd=folder_path, capture_output=True, text=True, shell=True)

        # Check if `npm install` was successful
        if npm_result.returncode != 0:
            return JsonResponse({"error": f"npm install failed: {npm_result.stderr}"}, status=500)

        # Run `hardhat test`
        test_result = subprocess.run('npx hardhat test', cwd=folder_path, capture_output=True, text=True, shell=True)

        # Check if the test command ran successfully
        if test_result.returncode != 0:
            return JsonResponse({"error": f"Test command failed: {test_result.stderr}"}, status=500)

        # Return the output of the test command as a response
        return JsonResponse({"data": test_result.stdout})

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
