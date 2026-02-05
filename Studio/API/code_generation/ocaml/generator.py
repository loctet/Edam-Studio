import os
import shutil
import subprocess
import time
from typing import Dict, Any
import uuid
from ..base_generator import BaseCodeGenerator
from ..tests import TestGenerator

class OCamlCodeGenerator(BaseCodeGenerator):
    def __init__(self, base_dir: str, temp_dir: str, output_dir: str, upload_dir: str, uid_p = None):
        super().__init__(base_dir, temp_dir, output_dir, upload_dir)
        self.ocaml_base_code = os.path.join(base_dir, "base_code", "ocaml_base_code.ml")
        self.ocaml_test_code = os.path.join(base_dir, "base_code", "ocaml_test_code.ml")
        self.cmd_base_code = os.path.join(base_dir, "base_code", "cmd_run.sh")
        
        uid = str(uuid.uuid4())
        if uid_p :
            uid = uid_p
        self.dirs = self.create_directories(uid)

    def generate_code(self, edam_instance: Any, server_settings: Dict) -> Dict:
        """Generate OCaml code for the given EDAM instance"""
        uid = self.dirs["uid"]
        dirs = self.dirs
        
        edam_name = edam_instance.get('name')
        edam_code = "let edam_instance : edam_type = " + edam_instance.get('edamCode') + """     
        let () = Printf.printf "%s" (generate_python_edam edam_instance list_of_vars)
        """

        # Create OCaml file
        ocaml_file = os.path.join(dirs["local_temp"], f"{uid}.ml")
        ocaml_output_file = os.path.join(dirs["local_temp"], f"Python_Edam_{time.time_ns()}_output.py")

        with open(ocaml_file, 'w', encoding="utf8") as f:
            with open(self.ocaml_base_code, 'r') as base:
                f.write(base.read())
            f.write("\n")
            f.write(edam_code)

        # Copy to src directory
        shutil.copy(ocaml_file, os.path.join(dirs["src"], f"{edam_name}_edam.ml"))

        # Run OCaml file
        try:
            #print(f"Running OCaml file: {ocaml_file}")
            with open(ocaml_output_file, 'a') as output_file:
                subprocess.run(
                    ["ocaml", ocaml_file],
                    stdout=output_file,
                    stderr=subprocess.PIPE,
                    check=True,
                    cwd=dirs["local_temp"]
                )
        except subprocess.CalledProcessError as e:
            raise Exception(f"\n\nOCaml execution failed for {edam_name}: {e.stderr.decode()} \n\n")
            return

        # Read and copy output
        with open(ocaml_output_file, 'r', encoding="utf8") as f:
            ocaml_result = f.read().strip()
        
        shutil.copy(ocaml_output_file, os.path.join(dirs["src"], f"{edam_name}_edam_output.py"))

        return {
            "ocaml_result": ocaml_result,
            "dirs": dirs,
            "uid": uid
        }

    def generate_test_code(self, edam_instance: Any, server_settings: Dict) -> Dict:
        """Generate test code for the given EDAM instance"""
        uid = self.dirs["uid"]
        dirs = self.dirs
        
        full_trace_test_tmp = os.path.join(dirs["local_temp"], f"full_trace_test_{uid}.ml")
        cmd_run_tmp = os.path.join(dirs["local_temp"], f"cmd_run_tmp_{uid}.sh")
        test_generator = TestGenerator()
        # Generate test code
        str_tests, edam_name = test_generator.generate_edam_test_code(edam_instance)
        
        with open(self.ocaml_test_code, 'r', encoding="utf8") as f:
            data_test_base_code = f.read()
            data_test_base_code = data_test_base_code.replace("{edams_code_here}", str_tests)
            
            for key, value in server_settings.items():
                placeholder = "{" + key + "}"
                data_test_base_code = data_test_base_code.replace(placeholder, str(value).lower())

            with open(full_trace_test_tmp, 'w', encoding="utf8") as ft:
                ft.write(data_test_base_code)

        # Copy test file
        shutil.copy(full_trace_test_tmp, os.path.join(dirs["src"], f"{edam_name}_edam_test.ml"))

        # Generate and copy command file
        with open(self.cmd_base_code, 'r') as f:
            trace_test_cmd = f.read()
            trace_test_cmd = trace_test_cmd.format(
                file_name=os.path.basename(full_trace_test_tmp).replace(".ml", ""),
                uid=uid
            )
            with open(cmd_run_tmp, 'w') as ft:
                ft.write(trace_test_cmd)
        
        shutil.copy(cmd_run_tmp, os.path.join(dirs["src"], f"{edam_name}_edam_test_cmd.sh"))

        return {
            "dirs": dirs,
            "uid": uid,
            "name": edam_name,
            "test_files": {
                "full_trace_test": full_trace_test_tmp,
                "cmd_run": cmd_run_tmp  # Use absolute path instead of relative path
            }
        } 