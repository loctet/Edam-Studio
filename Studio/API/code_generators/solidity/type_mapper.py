from typing import Dict, Any, Tuple

class SolidityTypeMapper:
    def map_type(self, dvar_type: str, var_name: str, is_param: bool = False) -> Tuple[str, Dict[str, Any]]:
        """
        Map dvar_type to Solidity type declaration or parameter.
        """
        memory_modifier = " memory" if is_param else ""
        visibility_modifier = " public " if not is_param else ""
        
        type_mapping = {
            "int": f"uint {visibility_modifier}{var_name}",
            "uint": f"uint {visibility_modifier}{var_name}",
            "bool": f"bool {visibility_modifier}{var_name}",
            "address": f"address {visibility_modifier}{var_name}",
            "user": f"address {visibility_modifier}{var_name}",
            "contract": f"address {visibility_modifier}{var_name}",
            "string": f"string{memory_modifier} {visibility_modifier}{var_name}",
            "list_int": f"uint[]{memory_modifier} {visibility_modifier}{var_name}",
            "list_bool": f"bool[]{memory_modifier} {visibility_modifier}{var_name}",
            "list_string": f"string[]{memory_modifier} {visibility_modifier}{var_name}",
            "map_address_bool": f"mapping(address => bool) {visibility_modifier}{var_name}",
            "map_address_int": f"mapping(address => uint) {visibility_modifier}{var_name}",
            "map_string_int": f"mapping(string => uint) {visibility_modifier}{var_name}",
            "map_string_string": f"mapping(string => string) {visibility_modifier}{var_name}",
            "map_address_string": f"mapping(address => string) {visibility_modifier}{var_name}",
            "map_map_address_string_bool": f"mapping(address => mapping(string => bool)) {visibility_modifier}{var_name}",
            "map_map_address_string_int": f"mapping(address => mapping(string => uint)) {visibility_modifier}{var_name}",
            "map_map_address_address_int": f"mapping(address => mapping(address => uint)) {visibility_modifier}{var_name}",
        }

        code_to_param = ""
        
        if dvar_type not in type_mapping:
            type_mapping[dvar_type] = f"{dvar_type} {visibility_modifier}_{var_name}"
            code_to_param = {"type": dvar_type, "name": var_name}

        return [type_mapping[dvar_type], code_to_param] 