from abc import ABC, abstractmethod
from typing import List, Dict, Any, Tuple
from objects.EdamClass import EDAM
from objects.TransitionClass import Transition
import json
from objects.Expressions import *

class BaseCodeGenerator(ABC):
    def __init__(self):
        self.used_functions = set()

    @abstractmethod
    def parse_tree(self, exp, caller="msg.sender", contract_name="address(this)"):
        """Parse an expression tree and generate code."""
        pass

    @abstractmethod
    def type_mapping(self, dvar_type: str, var_name: str, is_param: bool = False) -> Tuple[str, Dict[str, Any]]:
        """Map variable types to target language types."""
        pass

    @abstractmethod
    def parse_roles(self, pi, caller, contract):
        """Parse role conditions."""
        pass

    @abstractmethod
    def parse_roles_update(self, pi_prime, caller, contract):
        """Parse role updates."""
        pass

    @abstractmethod
    def generate_assignments(self, assignment, caller, contract):
        """Generate assignments."""
        pass

    @abstractmethod
    def process_deploy_transition(self, transition: Transition, contract_name: str):
        """Process deploy/start transition."""
        pass

    @abstractmethod
    def process_multiple_transitions(self, edam: EDAM, contract_name: str):
        """Process multiple transitions."""
        pass

    def generate_used_functions(self, used_functions):
        """Generate code for used functions."""
        included_functions = []
        for func in used_functions:
            if func in self.function_snippets:
                included_functions.append(self.function_snippets[func])
        return ( "// Included math functions\n\n" if included_functions else "") + "\n".join(included_functions)

    @property
    @abstractmethod
    def function_snippets(self) -> Dict[str, str]:
        """Get function snippets for the target language."""
        pass 

    def process_update_map(self, func_call):
        """
        Process a FuncCall of type "update_map".
        - If multiple identical nested update_map calls exist, replace them with their first argument (assumed to be Dvar).
        - Extract all unique update_map calls into separate grouped calls.
        
        :param func_call: The main FuncCall to process.
        :return: A tuple (main_func_call, grouped_calls), where:
                - main_func_call: The transformed main FuncCall with Dvar replacements.
                - grouped_calls: List of unique FuncCall instances.
        """
        if not isinstance(func_call, FuncCall) or func_call.operation != "update_map":
            raise ValueError("Function expects a FuncCall of operation 'update_map'.")

        nested_calls = []
        new_args = []

        # Recursive function to extract nested update_map calls
        def extract_update_map_args(arg, seen_calls, temp_var_map):
            if isinstance(arg, FuncCall) and arg.operation == "update_map":
                # Convert the arguments to a unique key for identification
                key = tuple(map(str, arg.arguments))
                
                if key not in seen_calls:
                    # Add to seen calls and keep a reference in nested_calls
                    seen_calls[key] = arg
                    nested_calls.append(arg)
                
                # Replace nested call with the first argument (assumed to be Dvar)
                if key not in temp_var_map:
                    temp_var_map[key] = arg.arguments[0]  # Replace with the first argument
                return temp_var_map[key]
            elif isinstance(arg, list):
                # Process lists recursively
                return [extract_update_map_args(a, seen_calls, temp_var_map) for a in arg]
            elif isinstance(arg, Exp):  # Check if the argument is an expression
                # Process nested expressions recursively
                if hasattr(arg, "__dict__"):  # Check if the argument has attributes to process
                    for attr_name, attr_value in arg.__dict__.items():
                        setattr(arg, attr_name, extract_update_map_args(attr_value, seen_calls, temp_var_map))
            return arg

        # Dictionary to track seen calls and temporary variable mappings
        seen_calls = {}
        temp_var_map = {}

        # Process the arguments of the main FuncCall
        for arg in func_call.arguments:
            new_args.append(extract_update_map_args(arg, seen_calls, temp_var_map))

        # Create the transformed main FuncCall
        main_func_call = FuncCall(func_call.operation, new_args)

        # Group unique update_map calls
        grouped_calls = list(seen_calls.values())

        return main_func_call, grouped_calls
    
    def generate_contract_data(self, edam_instance: EDAM):
        self.used_functions.clear()
        """ check_empty_role = edam_instance.is_empty_role_free() """
        data = {
            "fileContent": self.process_multiple_transitions(edam_instance, edam_instance.name),
            #"image_uri": generate_fsm_image_as_data_uri(edam_instance.transitions),
            "image_uri": "",
            "empty_role_check": "",
            "empty_role_check_issues": "" 
            """ 
            "empty_role_check": check_empty_role["check"],
            "empty_role_check_issues": check_empty_role["issues"] 
            """
        }
        return(json.dumps(data))