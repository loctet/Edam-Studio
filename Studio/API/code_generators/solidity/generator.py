"""
Main Solidity code generator class.

This module contains the main SolidityGenerator class that orchestrates
the generation of Solidity smart contract code from a EDAM representation.
"""

from typing import List, Dict, Any, Tuple, Type

from code_generators.base_generator import BaseCodeGenerator
from objects.EdamClass import EDAM
from objects.TransitionClass import Transition
from objects.Expressions import FuncCall
from code_generators.solidity.type_mapper import SolidityTypeMapper
from code_generators.solidity.role_handler import SolidityRoleHandler
from code_generators.solidity.expression_parser import SolidityExpressionParser
from code_generators.solidity.constants import (
    DEFAULT_CALLER,
    DEFAULT_CONTRACT,
    DEPLOY_OPERATIONS,
    UPDATE_OPERATIONS,
    TRUE_VALUES,
)
from code_generators.solidity.transition_grouping import TransitionGrouper
from code_generators.solidity.try_catch_builder import TryCatchBuilder
from code_generators.solidity.transition_processor import TransitionProcessor
from code_generators.solidity.constructor_builder import ConstructorBuilder
from code_generators.solidity.contract_assembler import ContractAssembler
from code_generators.solidity.utilities import GeneratorUtilities


class SolidityGenerator(BaseCodeGenerator):
    """
    Generates Solidity smart contract code from a EDAM (Decentralized Abstract Finite State Machine) representation.
    
    This class handles the transformation of EDAM transitions, roles, and expressions into
    valid Solidity contract code, including constructors, functions, state management, and
    role-based access control.
    """
    
    # Constants (for backward compatibility and easy access)
    DEFAULT_CALLER: str = DEFAULT_CALLER
    DEFAULT_CONTRACT: str = DEFAULT_CONTRACT
    DEPLOY_OPERATIONS: List[str] = DEPLOY_OPERATIONS
    UPDATE_OPERATIONS: List[str] = UPDATE_OPERATIONS
    TRUE_VALUES: List[str] = TRUE_VALUES
    
    def __init__(
        self,
        edam: EDAM,
        type_mapper: Type[SolidityTypeMapper] = SolidityTypeMapper,
        role_handler: Type[SolidityRoleHandler] = SolidityRoleHandler,
        expression_parser: Type[SolidityExpressionParser] = SolidityExpressionParser,
    ):
        """
        Initialize the Solidity generator.
        
        Args:
            edam: The EDAM instance to generate code from
            type_mapper: Class for mapping types to Solidity types
            role_handler: Class for handling role parsing and updates
            expression_parser: Class for parsing expressions into Solidity code
        """
        super().__init__()
        self.type_mapper = type_mapper()
        self.role_handler = role_handler()
        self.expression_parser = expression_parser(edam)
        self.expression_parser.contract_variables_with_type = {}
        self.contract_variables: List[str] = []
        
        # Initialize helper modules
        self.try_catch_builder = TryCatchBuilder(self)
        self.transition_processor = TransitionProcessor(self)
        self.transition_processor.set_try_catch_builder(self.try_catch_builder)
        self.constructor_builder = ConstructorBuilder(self)
        self.contract_assembler = ContractAssembler(self)
        self.utilities = GeneratorUtilities(self)
        self.grouper = TransitionGrouper(self.parse_tree)

    def parse_tree(
        self,
        exp: Any,
        caller: str = DEFAULT_CALLER,
        contract_name: str = DEFAULT_CONTRACT,
    ) -> Tuple[str, List[str]]:
        """
        Parse an expression tree and generate Solidity code.
        
        Args:
            exp: The expression to parse
            caller: The caller identifier (default: "msg.sender")
            contract_name: The contract name identifier (default: "address(this)")
            
        Returns:
            Tuple of (parsed_expression_code, external_calls_list)
        """
        return self.expression_parser.parse_tree(exp, caller, contract_name)

    def type_mapping(
        self, dvar_type: str, var_name: str, is_param: bool = False
    ) -> Tuple[str, Dict[str, Any]]:
        """
        Map a EDAM variable type to its Solidity equivalent.
        
        Args:
            dvar_type: The EDAM variable type
            var_name: The variable name
            is_param: Whether this is a function parameter
            
        Returns:
            Tuple of (solidity_type_declaration, optional_import_data)
        """
        return self.type_mapper.map_type(dvar_type, var_name, is_param)

    def parse_roles(self, rho: Any, caller: str, contract: str) -> str:
        """
        Parse role conditions into Solidity code.
        
        Args:
            rho: The role condition expression
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            Solidity code string for role checks
        """
        return self.role_handler.parse_roles(rho, caller, contract)

    def parse_roles_update(self, rho_prime: Any, caller: str, contract: str) -> List[str]:
        """
        Parse role updates into Solidity code.
        
        Args:
            pi_prime: The role update expression
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            List of Solidity code strings for role updates
        """
        return self.role_handler.parse_roles_update(rho_prime, caller, contract)

    def remove_all_true_in_conditions(self, conditions: List[str]) -> List[str]:
        """
        Filter out standalone 'True' and 'true' values from conditions list.
        Note: This should not be used for guard conditions - guards should always be kept.
        
        Args:
            conditions: List of condition strings
            
        Returns:
            Filtered list with True values removed
        """
        # Filter out literal "True"/"true" strings, but keep guard expressions
        # Guards should be kept even if they evaluate to "true"
        return [condition for condition in conditions if condition not in TRUE_VALUES]

    def generate_assignments(
        self, assignment: Tuple[Any, Any], caller: str, contract: str
    ) -> List[str]:
        """
        Generate Solidity assignment statements from a EDAM assignment.
        
        Args:
            assignment: Tuple of (variable, expression)
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            List of Solidity assignment code strings
        """
        dvar, exp = assignment
        lhs = ""
        
        if isinstance(exp, FuncCall):
            rhs = self._process_func_call_assignment(exp, dvar, caller, contract)
            if exp.operation not in UPDATE_OPERATIONS:
                lhs = f"{dvar.var_name} = "
        else:
            rhs, _ = self.parse_tree(exp, caller, contract)
            lhs = f"{dvar.var_name} = "
        
        return [f"{lhs} {rhs}"]

    def _process_func_call_assignment(
        self, exp: FuncCall, dvar: Any, caller: str, contract: str
    ) -> str:
        """
        Process a function call expression for assignment generation.
        
        Args:
            exp: The function call expression
            dvar: The destination variable
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            Right-hand side of the assignment as a string
        """
        if exp.operation == "update_map":
            return self._process_update_map_assignment(exp, caller, contract)
        elif exp.operation in UPDATE_OPERATIONS:
            rhs, _ = self.parse_tree(exp, caller, contract)
            return rhs
        else:
            rhs, _ = self.parse_tree(exp, caller, contract)
            return rhs

    def _process_update_map_assignment(
        self, exp: FuncCall, caller: str, contract: str
    ) -> str:
        """
        Process update_map operations by extracting and parsing nested calls.
        
        Args:
            exp: The update_map function call expression
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            Concatenated Solidity code for all update_map operations
        """
        parsed_statements = []
        updated_call, extracted_updates = self.process_update_map(exp)
        
        parsed_statements.append(
            self.parse_tree(updated_call, caller, contract)[0]
        )
        
        for extracted_exp in extracted_updates:
            parsed_statements.append(
                self.parse_tree(extracted_exp, caller, contract)[0]
            )
        
        # Remove duplicates and join with semicolons
        unique_statements = list(set(parsed_statements))
        return ";\n\t\t\t".join(unique_statements)

    def process_deploy_transition(
        self, transition: Transition, contract_name: str, contract_data_types: List[Tuple[str, Any]] = None
    ) -> Tuple[str, str]:
        """
        Process a deploy/start transition and generate constructor code.
        
        Args:
            transition: The deploy/start transition
            contract_name: The contract name
            contract_data_types: List of (type, variable) tuples from EDAM
            
        Returns:
            Tuple of (constructor_code, import_statements)
        """
        return self.constructor_builder.process_deploy_transition(transition, contract_name, contract_data_types)

    def process_multiple_transitions(
        self, edam: EDAM, contract_name: str
    ) -> str:
        """
        Process all transitions in a EDAM and generate a complete Solidity contract.
        
        Args:
            edam: The EDAM instance to process
            contract_name: The name of the contract to generate
            
        Returns:
            Complete Solidity contract code as a string
        """
        states = set(edam.get("states"))
        roles_list = self.utilities.extract_roles_list(edam.get("roles_list"))
        
        has_role_updates = self.utilities.check_has_role_updates(edam, contract_name)
        
        constructor_code, code_to_import = self._process_constructor_transition(
            edam, contract_name
        )
        
        operation_map, has_external_calls = self.transition_processor.process_regular_transitions(
            edam, contract_name
        )
        
        # Ensure _permissions is added once (after all transitions processed)
        self.utilities.ensure_users_permissions_variable()
        
        functions_code = self.contract_assembler.generate_function_code(operation_map, has_external_calls)
        enum_states = self.contract_assembler.generate_state_enum(states)
        enum_role_list = self.contract_assembler.generate_role_enum(roles_list)
        math_functions_code = self.generate_used_functions(
            self.expression_parser.used_functions
        )
        
        contract_code = self.contract_assembler.assemble_contract(
            contract_name=contract_name,
            imports=code_to_import,
            enum_states=enum_states,
            enum_role_list=enum_role_list,
            constructor_code=constructor_code,
            functions_code=functions_code,
            math_functions_code=math_functions_code,
            has_external_calls=has_external_calls,
            has_role_updates=has_role_updates,
        )
        
        return contract_code

    def _process_constructor_transition(
        self, edam: EDAM, contract_name: str
    ) -> Tuple[str, str]:
        """
        Process constructor (deploy/start) transitions.
        Handles multiple start transitions with different guard conditions by generating if-else blocks.
        
        Args:
            edam: The EDAM instance
            contract_name: The contract name
            
        Returns:
            Tuple of (constructor_code, import_statements)
        """
        # Get contract_data_types from EDAM
        contract_data_types = edam.get("contract_data_types") or []
        
        # Collect all deploy/start transitions
        deploy_transitions = [
            t for t in edam.get("transitions")
            if t.operation.lower() in DEPLOY_OPERATIONS
        ]
        
        if not deploy_transitions:
            return "", ""
        
        # Process multiple start transitions with different guard conditions
        return self.constructor_builder.process_multiple_deploy_transitions(
            deploy_transitions, contract_name, contract_data_types
        )
    
    # Delegate methods to utilities for backward compatibility
    def _extract_roles_list(self, roles_list: List[str]) -> set:
        """Extract and filter valid roles from the roles list."""
        return self.utilities.extract_roles_list(roles_list)
    
    def _check_has_role_updates(self, edam: EDAM, contract_name: str) -> bool:
        """Check if any transition in the EDAM has role updates."""
        return self.utilities.check_has_role_updates(edam, contract_name)
    
    def _process_assignments_and_params(
        self,
        assignments: List[Tuple[Any, Any]],
        data_params: List[Tuple[str, Any]],
        caller: str,
        contract: str,
    ) -> Tuple[List[str], List[Dict[str, str]]]:
        """Process assignments and data parameters."""
        return self.utilities.process_assignments_and_params(
            assignments, data_params, caller, contract
        )
    
    def _generate_params(
        self, data_params: List[Tuple[str, Any]], ptp_vars: List[str]
    ) -> List[str]:
        """Generate parameter list strings for function/constructor signatures."""
        return self.utilities.generate_params(data_params, ptp_vars)
    
    def _build_role_assertion(
        self, role_updates: Any, caller: str, contract: str
    ) -> str:
        """Build role assertion require statement."""
        return self.constructor_builder.build_role_assertion(role_updates, caller, contract)
    
    @property
    def function_snippets(self) -> Dict[str, str]:
        """Get function snippets dictionary for Solidity code generation."""
        from code_generators.solidity.snippets import function_snippets
        return function_snippets
