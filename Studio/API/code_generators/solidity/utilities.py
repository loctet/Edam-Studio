"""
Utility functions for Solidity code generation.
"""

from typing import List, Tuple, Any, Dict

from code_generators.solidity.constants import (
    UPDATE_OPERATIONS,
    USERS_PERMISSIONS_DECLARATION,
)


class GeneratorUtilities:
    """Utility functions for the generator."""
    
    def __init__(self, generator):
        """
        Initialize the utilities.
        
        Args:
            generator: Reference to the SolidityGenerator instance
        """
        self.generator = generator
    
    def process_assignments_and_params(
        self,
        assignments: List[Tuple[Any, Any]],
        data_params: List[Tuple[str, Any]],
        caller: str,
        contract: str,
    ) -> Tuple[List[str], List[Dict[str, str]]]:
        """
        Process assignments and data parameters, generating Solidity code and contract variables.
        
        Args:
            assignments: List of (variable, expression) tuples
            data_params: List of (type, variable) tuples for contract data
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            Tuple of (solidity_assignments_list, contract_data_types_list)
        """
        solidity_assignments = []
        # Preserve existing contract_variables (may have been set from EDAM contract_data_types)
        if self.generator.contract_variables is None:
            self.generator.contract_variables = []
        contract_data_types = []
        
        for dvar_type, dvar in data_params:
            var_name = dvar.var_name
            type_declaration, import_data = self.generator.type_mapping(dvar_type, var_name)
            
            # Only add to contract_variables if it's an external type (contract import)
            # Regular function parameters (int, uint, bool, etc.) should NOT be added as contract variables
            # Only external types (those with import_data) should be stored as contract-level variables
            if import_data:
                # This is an external type (contract import) - add as contract variable
                if type_declaration not in self.generator.contract_variables:
                    self.generator.contract_variables.append(type_declaration)
                contract_data_types.append(import_data)
            
            # Always register the type for expression parsing (needed for both function params and contract vars)
            self.generator.expression_parser.contract_variables_with_type[var_name] = dvar_type
        
        for assignment in assignments:
            solidity_assignments.extend(
                self.generator.generate_assignments(assignment, caller, contract)
            )
        
        # Don't call ensure_users_permissions_variable here - it's called once at contract level
        # to avoid adding it multiple times for each transition
        
        return solidity_assignments, contract_data_types
    
    def ensure_users_permissions_variable(self) -> None:
        """
        Ensure users_permissions mapping is included in contract variables if not present.
        Only adds it once, even if called multiple times.
        """
        # Check if users_permissions is already in contract_variables
        # by checking if the declaration string or variable name appears
        has_users_permissions = any(
            "_permissions" in var for var in self.generator.contract_variables
        )
        
        if not has_users_permissions:
            self.generator.contract_variables.append(USERS_PERMISSIONS_DECLARATION)
    
    def generate_params(
        self, data_params: List[Tuple[str, Any]], ptp_vars: List[str]
    ) -> List[str]:
        """
        Generate parameter list strings for function/constructor signatures.
        
        Args:
            data_params: List of (type, variable) tuples
            ptp_vars: List of participant variable names (addresses)
            
        Returns:
            List of parameter declaration strings
        """
        params = []

        # Add participant variables as addresses
        for ptp_var in ptp_vars:
            params.append(f"address {ptp_var}")

        # Add data parameters with their mapped types
        for dvar_type, dvar in data_params:
            type_declaration, _ = self.generator.type_mapping(
                dvar_type, dvar.var_name, is_param=True
            )
            params.append(type_declaration)

        return params
    
    def extract_roles_list(self, roles_list: List[str]) -> set:
        """
        Extract and filter valid roles from the roles list.
        
        Args:
            roles_list: List of role strings
            
        Returns:
            Set of valid (non-empty, non-None) roles
        """
        return {role for role in roles_list if role and role != ""}
    
    def check_has_role_updates(self, edam, contract_name: str) -> bool:
        """
        Check if any transition in the EDAM has role updates.
        
        Args:
            edam: The EDAM instance to check
            contract_name: The contract name identifier
            
        Returns:
            True if at least one transition has role updates, False otherwise
        """
        for transition in edam.get("transitions"):
            role_updates = self.generator.parse_roles_update(
                transition.role_updates,
                transition.initiator,
                contract_name,
            )
            if role_updates:
                return True
        return False

