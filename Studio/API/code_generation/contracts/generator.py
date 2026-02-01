import os
import json
import subprocess
from typing import Dict, Any
import uuid
from ..base_generator import BaseCodeGenerator
from code_generators.solidity.generator import SolidityGenerator
from objects.EdamClass import EDAM
from ..ocaml.generator import OCamlCodeGenerator

class ContractCodeGenerator(BaseCodeGenerator):
    def __init__(self, base_dir: str, temp_dir: str, output_dir: str, upload_dir: str, dirs = []):
        super().__init__(base_dir, temp_dir, output_dir, upload_dir)
        self.dirs = dirs

    def generate_code(self, edam_instance: EDAM, server_settings: Dict) -> Dict:
        """Generate contract code for the given EDAM instance"""
        dirs = self.dirs 
        
        edam_name = edam_instance.get('name')
        sol_generator = SolidityGenerator(edam_instance)

        # Generate Solidity contract
        data_sol = json.loads(sol_generator.generate_contract_data(edam_instance))
        sol_file = os.path.join(dirs["contracts"], f"{edam_name}.sol")
        with open(sol_file, 'w', encoding='utf-8') as f:
            f.write(data_sol["fileContent"])

        return {
            "sol_data": data_sol
        }

    def generate_test_code(self, edam_instance: Any, server_settings: Dict) -> Dict:
        """Generate test code for the given EDAM instance"""
        dirs = self.dirs 
       
        ocaml_code_generator = OCamlCodeGenerator(self.base_dir, self.temp_dir, self.output_dir, self.upload_dir, dirs["uid"])
        data = ocaml_code_generator.generate_test_code(edam_instance, server_settings)
        edam_name = data["name"]
        
        ocaml_code_generator.copy_base_files(dirs, edam_name)
        ocaml_code_generator.copy_list_file_to_dir(dirs, "local_temp")
        
        
        # Run test generation
        data_test_result = self._run_test_generation(dirs, data["test_files"]["cmd_run"], server_settings)
        
        # Generate test files
        test_file = os.path.join(dirs["test"], f"{edam_name}_test.js")
        symbolic_test_file = os.path.join(dirs["test"], f"{edam_name}_symbolic_test.txt")
        migration_file = os.path.join(dirs["migrations"], f"1_{edam_name}_migration.js")
        
        
        # Write test files
        with open(symbolic_test_file, 'w', encoding='utf-8') as f:
            #for trace in data_test_result['data_symbolic_test']:
            f.writelines(data_test_result[0].split("++++++++++++++++++++++++"))

        with open(test_file, 'w', encoding='utf-8') as f:
            f.write(data_test_result[1])

        with open(migration_file, 'w', encoding='utf-8') as f:
            f.write(data_test_result[2])

        return {
            "dirs": dirs,
            "test_files": {
                "test": test_file,
                "symbolic_test": symbolic_test_file,
                "migration": migration_file
            }
        }

    def _run_test_generation(self, dirs: Dict[str, str], file_path: str, server_settings: Dict) -> Dict:
        """Run test generation process"""
        test_file_tmp = os.path.join(dirs["local_temp"], f"{uuid.uuid4()}.js")
        data_tests = ["", "", ""]

        try:
            with open(test_file_tmp, 'w', encoding='utf-8') as output_file:
                # Run script from base_dir since the script uses relative paths (cd ./temp/temp_{uid})
                subprocess.run(
                    ["bash", file_path],
                    stdout=output_file,
                    stderr=subprocess.PIPE,
                    check=True,
                    cwd=self.base_dir  # Run from base_dir so ./temp/ path in script works
                )
            
            with open(test_file_tmp, 'r', encoding='utf-8') as f:
                data = f.read()
                data_tests= data.split("________")
                return data_tests
        except subprocess.CalledProcessError as e:
            print(e.stderr.decode())
            raise Exception(f"Test generation failed for {file_path}: {e.stderr.decode()}") 
        
            return data_tests
        
        except Exception as e :
            return data_tests