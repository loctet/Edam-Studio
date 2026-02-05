from abc import ABC, abstractmethod
from typing import Dict, List, Any, Tuple
import os
import uuid
import shutil
import subprocess
import json
import zipfile

class BaseCodeGenerator(ABC):
    def __init__(self, base_dir: str, temp_dir: str, output_dir: str, upload_dir: str):
        self.base_dir = base_dir
        self.base_code_dir = os.path.join(base_dir, "base_code")
        self.temp_dir = temp_dir
        self.output_dir = output_dir
        self.upload_dir = upload_dir
        self.used_functions = set()
        self.list_of_files = ["printer.ml", "core_functions.ml", "test_generation.ml", "helper.ml", "z3_module.ml", "types.ml"]

    @abstractmethod
    def generate_code(self, edam_instance: Any, server_settings: Dict) -> Dict:
        """Generate code for the given EDAM instance"""
        pass

    @abstractmethod
    def generate_test_code(self, edam_instance: Any, server_settings: Dict) -> Dict:
        """Generate test code for the given EDAM instance"""
        pass

    def create_directories(self, uid: str) -> Dict[str, str]:
        """Create necessary directories for code generation"""
        local_temp_dir = os.path.join(self.temp_dir, f"temp_{uid}")
        rep_dir = os.path.join(self.output_dir, uid)
        dirs = {
            "local_temp": local_temp_dir,
            "rep": rep_dir,
            "contracts": os.path.join(rep_dir, "contracts"),
            "test": os.path.join(rep_dir, "test"),
            "migrations": os.path.join(rep_dir, "migrations"),
            "src": os.path.join(rep_dir, "src"),
            "sources": os.path.join(rep_dir, "sources"),
            "builds": os.path.join(rep_dir, "builds")
        }

        for dir_path in dirs.values():
            os.makedirs(dir_path, exist_ok=True)

        dirs["uid"] = uid
        return dirs

    def copy_base_files(self, dirs: Dict[str, str], model: str = ""):
        """Copy base files to the output directory"""
        base_code_dir = self.base_code_dir
        # Copy package.json and config files
        shutil.copy(os.path.join(base_code_dir, "base_package.json"), 
                   os.path.join(dirs["rep"], "package.json"))
        shutil.copy(os.path.join(base_code_dir, "base_hardhat.config.js"), 
                   os.path.join(dirs["rep"], "hardhat.config.js"))
        
        with open(os.path.join(base_code_dir, "Move.toml")) as f :
            content = f.read()
            content = content.format(module_name = model.lower())
            with open( os.path.join(dirs["rep"], "Move.toml"), "w") as g :
                g.write(content)

        
        
        # Copy run script and make it executable
        run_src = os.path.join(base_code_dir, "run")
        run_dest = os.path.join(dirs["rep"], "run")
        shutil.copy(run_src, run_dest)
        os.chmod(run_dest, 0o755)

        self.copy_list_file_to_dir(dirs)

    def copy_list_file_to_dir(self, dirs: Dict[str, str], to: str = "src") :
        base_code_dir = self.base_code_dir

        # Copy other base files
        for name in self.list_of_files:
            shutil.copy(os.path.join(base_code_dir, name), 
                        os.path.join(dirs[to], name))


    def create_zip_file(self, dirs: Dict[str, str], edam_name: str, server_settings: Dict, 
                       diff_time: int) -> str:
        """Create a zip file of the generated code"""
        int_number_real_traces = int(server_settings["number_real_traces"]) * int(server_settings["number_symbolic_traces"])
        #print(f"int_number_real_traces: {int_number_real_traces} = {int(server_settings['number_real_traces'])} * {int(server_settings['number_symbolic_traces'])}")
        zip_filename = f"{edam_name}_{int_number_real_traces}_{server_settings['probability_new_participant']}_{'pi' if server_settings['add_pi_to_test'] else 'no_pi'}_{str(uuid.uuid4())}_{diff_time}.zip"
        zip_filename_path = os.path.join(self.upload_dir, zip_filename)

        with zipfile.ZipFile(zip_filename_path, 'w') as zipf:
            for root, _, files in os.walk(dirs["rep"]):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, dirs["rep"])
                    zipf.write(file_path, arcname)

        return zip_filename

    def cleanup(self, dirs: Dict[str, str]):
        """Clean up temporary directories"""
        shutil.rmtree(dirs["rep"], ignore_errors=True)
        shutil.rmtree(dirs["local_temp"], ignore_errors=True) 