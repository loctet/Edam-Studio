import time
import threading
from queue import Queue
from typing import Dict, List, Any
from django.http import JsonResponse
from objects.EdamClass import EDAM
from objects.TransitionClass import Transition
from objects.Expressions import *

from .ocaml.generator import OCamlCodeGenerator
from .contracts.generator import ContractCodeGenerator

class CodeGenerationProcess:
    def __init__(self, base_dir: str, temp_dir: str, output_dir: str, upload_dir: str):
        self.base_dir = base_dir
        self.temp_dir = temp_dir
        self.output_dir = output_dir
        self.upload_dir = upload_dir
        self.ocaml_generator = OCamlCodeGenerator(self.base_dir, self.temp_dir, self.output_dir, self.upload_dir)
        self.contract_generator = ContractCodeGenerator(self.base_dir, self.temp_dir, self.output_dir, self.upload_dir, self.ocaml_generator.dirs)
    
    def process_models(self, body: Dict, with_response: bool = True) -> Dict:
        """Process multiple models in bulk"""
        try:
            models = body["models"]
            server_settings = body["server_settings"]
            zip_filename, results_output = self._process_models(models, server_settings, with_response)
            
            result = {
                            "zip_url": zip_filename,
                            "images": results_output["list_of_images"],
                            "list_contents": results_output["list_of_contents"],
                            "list_empty_role_check": results_output["list_empty_role_check"],
                            "list_empty_role_check_issues": results_output["list_empty_role_check_issues"]
                        }
            return JsonResponse(result) if with_response else result

        except Exception as e:
            print(e)
            if with_response:
                return JsonResponse({"error": str(e)}, status=500)
            raise


    def process_model_bulk(self, body: Dict, with_response: bool = True) -> Dict:
        """Process multiple models in bulk"""
        try:
            models = body["models"]
            server_settings = body["server_settings"]
            mode_generation = int(body.get("generation_mode", 2))

            results = []
            threads = []
            lock = threading.Lock()
            queue = Queue()

            def worker():
                while not queue.empty():
                    models, server_settings = queue.get()
                    data = [models] if type(models) is not list else models
                    zip_filename, results_output = self._process_models(data, server_settings, with_response)
                    with lock:
                        results.append({
                            "zip_url": zip_filename,
                            "images": results_output["list_of_images"],
                            "list_contents": results_output["list_of_contents"],
                            "list_empty_role_check": results_output["list_empty_role_check"],
                            "list_empty_role_check_issues": results_output["list_empty_role_check_issues"]
                        })
                    queue.task_done()
            
            # Queue models for processing
            if mode_generation == 3:
                queue.put((models, server_settings.copy()))
            # Queue models one by one for processing
            elif mode_generation == 4:
                for model in models:
                    queue.put((model, server_settings.copy()))
            else :
                # Bulk 
                for n_s_t in [server_settings["number_symbolic_traces"]]:
                    range_ = list(range(1, 2))
                    if mode_generation == 2:
                        range_ = sorted(([0.01, 0.02, 0, 1] + list(range(1, 2))))

                    for i in range_:
                        server_settings["number_symbolic_traces"] = int(n_s_t / 5)
                        server_settings["probability_new_participant"] = i / 10
                        
                        if mode_generation == 1:
                            for model in models:
                                queue.put((model, server_settings.copy()))
                        else:
                            queue.put((models, server_settings.copy()))

            # Start worker threads
            for _ in range(min(1, queue.qsize())):
                thread = threading.Thread(target=worker)
                threads.append(thread)
                thread.start()

            # Wait for all threads to complete
            for thread in threads:
                thread.join()

            return JsonResponse(results[-1]) if with_response else results[-1]

        except Exception as e:
            print(e)
            if with_response:
                return JsonResponse({"error": str(e)}, status=500)
            raise

    def _process_models(self, data: List[Dict], server_settings: Dict, with_response: bool) -> tuple:
        """Process individual models"""
        start_time = time.time_ns()
        results_output = {
            "list_of_images": [],
            "list_of_contents": [],
            "list_empty_role_check": [],
            "list_empty_role_check_issues": [],
        }
        
        self.ocaml_generator = OCamlCodeGenerator(self.base_dir, self.temp_dir, self.output_dir, self.upload_dir)
        self.contract_generator = ContractCodeGenerator(self.base_dir, self.temp_dir, self.output_dir, self.upload_dir, self.ocaml_generator.dirs)
        
        # print(self.contract_generator.dirs)
        # print("----------1")
        for edam in data:
            # Generate OCaml code
            ocaml_result = self.ocaml_generator.generate_code(edam, server_settings)
            
            try:
                # Generate contract code
                contract_result = self.contract_generator.generate_code(
                    eval(ocaml_result["ocaml_result"]), 
                    server_settings
                )
                # Update results
                results_output["list_of_images"].append(contract_result["sol_data"]["image_uri"])
                results_output["list_of_contents"].append(contract_result["sol_data"]["fileContent"])
                #results_output["list_of_contents"].append(contract_result["move_data"]["fileContent"])
                results_output["list_empty_role_check"].append(
                    (edam["name"], contract_result["sol_data"]["empty_role_check"])
                )
                results_output["list_empty_role_check_issues"].append(
                    (edam["name"], contract_result["sol_data"]["empty_role_check_issues"])
                )

            except Exception as e:
                print(e)
                print("Eroorrrrrrrr")
                if with_response:
                    return JsonResponse({"error": str(e)}, status=500)
                raise

        # print()
        # print("-----------2")
        # print(self.contract_generator.dirs)
        # Generate test code
        test_result = self.contract_generator.generate_test_code(
            data,
            server_settings
        )
        # Create zip file
        diff_time = time.time_ns() - start_time
        zip_filename = self.contract_generator.create_zip_file(
            self.contract_generator.dirs,
            edam["name"],
            server_settings,
            diff_time
        )
        # print(12)
        # Cleanup
        self.contract_generator.cleanup(self.contract_generator.dirs)

        return zip_filename, results_output 