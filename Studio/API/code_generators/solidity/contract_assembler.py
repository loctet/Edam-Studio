"""
Utilities for assembling the final Solidity contract.
"""

from typing import Dict, Any

from code_generators.solidity.constants import (
    DEFAULT_STATE,
    DEFAULT_ROLE,
    STATE_VARIABLE_DECLARATION,
    REENTRANT_CALL_MESSAGE,
)
from code_generators.solidity.templates import (
    SOLIDITY_CONTRACT_TEMPLATE,
    SOLIDITY_FUNCTION_TEMPLATE,
)
from code_generators.solidity.snippets import function_snippets, generate_roles_overloads


class ContractAssembler:
    """Helper class for assembling the final contract."""
    
    def __init__(self, generator):
        """
        Initialize the contract assembler.
        
        Args:
            generator: Reference to the SolidityGenerator instance
        """
        self.generator = generator
    
    def generate_function_code(
        self, operation_map: Dict[str, Dict[str, Any]], has_external_calls: bool
    ) -> str:
        """
        Generate function code from operation map.
        
        Args:
            operation_map: Dictionary mapping operations to their data
            has_external_calls: Whether any function has external calls
            
        Returns:
            Complete functions code string
        """
        functions = []
        reentrancy_modifier = "nonReentrant" if has_external_calls else ""
        
        for operation, data in operation_map.items():
            params = data["params"]
            bodies = " else ".join(data["bodies"])
            
            function_code = SOLIDITY_FUNCTION_TEMPLATE.format(
                operation=operation,
                params=params,
                reentrancy_modifier=reentrancy_modifier,
                bodies=bodies,
            )
            
            functions.append(function_code)
        
        return "\n".join(functions)
    
    def generate_state_enum(self, states: set) -> str:
        """
        Generate State enum declaration.
        
        Args:
            states: Set of state identifiers
            
        Returns:
            State enum declaration string
        """
        if states:
            sorted_states = ", ".join(sorted(states))
            return f"enum State {{ {sorted_states} }}"
        return f"enum State {{{DEFAULT_STATE}}}"
    
    def generate_role_enum(self, roles_list: set) -> str:
        """
        Generate Roles enum declaration.
        
        Args:
            roles_list: Set of role identifiers
            
        Returns:
            Roles enum declaration string
        """
        if roles_list:
            sorted_roles = ", ".join(sorted(roles_list))
            return f"enum Roles {{ {sorted_roles} }}"
        return f"enum Roles{{{DEFAULT_ROLE}}}"
    
    def assemble_contract(
        self,
        contract_name: str,
        imports: str,
        enum_states: str,
        enum_role_list: str,
        constructor_code: str,
        functions_code: str,
        math_functions_code: str,
        has_external_calls: bool,
        has_role_updates: bool,
    ) -> str:
        """
        Assemble all components into a complete Solidity contract.
        
        Args:
            contract_name: The contract name
            imports: Import statements
            enum_states: State enum declaration
            enum_role_list: Roles enum declaration
            constructor_code: Constructor code
            functions_code: Functions code
            math_functions_code: Math functions code
            has_external_calls: Whether to include reentrancy protection
            has_role_updates: Whether to include roleSatisf function (only if role updates exist)
            
        Returns:
            Complete Solidity contract code
        """
        non_reentrancy_variables = (
            self.get_non_reentrancy_code() if has_external_calls else ""
        )
        
        # Only include roleSatisf function if there are role updates in the contract
        other_code_parts = [math_functions_code]
        if has_role_updates:
            role_satisf_code = function_snippets["roleSatisf"]
            
            # Get the parameter counts used for _roles calls and generate overloads dynamically
            roles_parameter_counts = self.generator.role_handler.get_roles_parameter_counts()
            roles_overloads = generate_roles_overloads(roles_parameter_counts)
            
            # Combine roleSatisf function with dynamically generated _roles overloads
            if roles_overloads:
                role_satisf_code = role_satisf_code.rstrip() + "\n    " + roles_overloads
            
            other_code_parts.append(role_satisf_code)
        other_code = "\n\t".join(filter(None, other_code_parts))
        
        if self.generator.contract_variables:
            # Add tab indentation to all contract variables
            contract_variables = "\t" + ";\n\t".join(self.generator.contract_variables)
        else:
            contract_variables = ""
        
        return SOLIDITY_CONTRACT_TEMPLATE.format(
            imports=imports,
            contract_name=contract_name,
            enum_states=enum_states,
            enum_role_list=enum_role_list,
            state_variable=STATE_VARIABLE_DECLARATION,
            contract_variables=contract_variables,
            non_reentrancy_variables=non_reentrancy_variables,
            constructor_code=constructor_code,
            functions_code=functions_code,
            other_code=other_code,
        )
    
    def get_non_reentrancy_code(self) -> str:
        """
        Get the non-reentrancy protection code.
        
        Returns:
            Non-reentrancy modifier code string
        """
        return f"""
        bool private _entered;
        modifier nonReentrant() {{
            require(!_entered, "{REENTRANT_CALL_MESSAGE}");
            _entered = true;
            _;
            _entered = false;
        }}
        """

