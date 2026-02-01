"""
Utilities for building constructor code.
"""

from typing import List, Tuple, Any, Dict

from objects.TransitionClass import Transition
from code_generators.solidity.constants import (
    DEPLOY_OPERATIONS,
    ROLE_CONSTRAINT_MESSAGE,
    CONDITION_NOT_MET_MESSAGE,
)
from code_generators.solidity.templates import SOLIDITY_CONSTRUCTOR_TEMPLATE


class ConstructorBuilder:
    """Helper class for building constructor code."""
    
    def __init__(self, generator):
        """
        Initialize the constructor builder.
        
        Args:
            generator: Reference to the SolidityGenerator instance
        """
        self.generator = generator
    
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
            
        Raises:
            ValueError: If transition is not a deploy/start operation
        """
        if transition.operation.lower() not in DEPLOY_OPERATIONS:
            raise ValueError(
                f"Transition '{transition.operation}' is not a deploy transition (constructor)."
            )

        # Process contract_data_types from EDAM to generate contract variables
        if contract_data_types:
            self._process_contract_data_types_for_variables(contract_data_types, contract_name)

        guard_conditions, _ = self.generator.parse_tree(
            transition.guard, transition.initiator, contract_name
        )

        # Process contract_data_types through _process_assignments_and_params to get contract import assignments
        # This ensures contract imports are assigned before external calls (same as regular functions)
        # Note: contract_data_types are processed here to ensure contract variables are set up before external calls
        solidity_assignments, _ = self.generator._process_assignments_and_params(
            transition.assignments,
            contract_data_types if contract_data_types else [],  # Process contract_data_types for assignments
            transition.initiator,
            contract_name,
        )

        # Process contract_data_types for constructor parameters
        import_statements, param_code, assignment_code = (
            self.process_contract_data_types(contract_data_types) if contract_data_types else ("", [], [])
        )

        constructor_params = self.build_constructor_params(
            transition.parameters, transition.participants, param_code
        )

        role_updates = self.generator.parse_roles_update(
            transition.role_updates, transition.initiator, contract_name
        )

        combined_conditions = self.build_combined_conditions(guard_conditions)
        role_assertion = self.build_role_assertion(
            transition.role_updates, transition.initiator, contract_name
        )

        # Use try-catch builder for external calls (same mechanism as regular functions)
        # This ensures external calls are wrapped in try-catch blocks with proper error handling
        if transition.external_calls:
            # Contract import assignments (from constructor parameters) must be placed BEFORE external calls
            # This ensures contract variables are initialized before making external calls
            # Use try-catch builder to handle external calls (same as regular functions)
            # The try-catch builder processes assignments, role updates, state change, and external calls
            try_catch_body = self.generator.try_catch_builder.build_try_catch_for_transition(
                transition, contract_name
            )
            
            # Prepend contract import assignments before external calls
            # assignment_code contains assignments like "contractName = _contractName"
            if assignment_code:
                assignment_statements = "\t\t" + ";\n\t\t".join(assignment_code)
                constructor_body = f"{assignment_statements};\n\t\t{try_catch_body}"
            else:
                constructor_body = try_catch_body
        else:
            # No external calls, build body normally
            constructor_body = self.build_constructor_body(
                [],
                assignment_code,
                solidity_assignments,
                role_updates,
                transition.target_state,
                role_assertion,
            )

        body = self.wrap_with_condition_check(combined_conditions, constructor_body)

        reentrancy_modifier = (
            "nonReentrant" if transition.external_calls else ""
        )

        constructor_code = SOLIDITY_CONSTRUCTOR_TEMPLATE.format(
            constructor_params=constructor_params,
            reentrancy_modifier=reentrancy_modifier,
            bodies=body,
        )

        return constructor_code, import_statements
    
    def _process_contract_data_types_for_variables(
        self, contract_data_types: List[Tuple[str, Any]], contract_name: str
    ) -> None:
        """
        Process contract data types from EDAM and generate contract variable declarations.
        
        Args:
            contract_data_types: List of (type, variable) tuples from EDAM
            contract_name: Contract name for context
        """
        for dvar_type, dvar in contract_data_types:
            var_name = dvar.var_name
            type_declaration, _ = self.generator.type_mapping(dvar_type, var_name)
            
            self.generator.contract_variables.append(type_declaration)
            self.generator.expression_parser.contract_variables_with_type[var_name] = dvar_type
    
    def process_contract_data_types(
        self, contract_data_types: List[Tuple[str, Any]]
    ) -> Tuple[str, List[str], List[str]]:
        """
        Process contract data types and generate import statements and parameter code.
        Only processes types that are NOT in the built-in typing list (external types).
        External types are those that require imports and constructor parameters.
        
        Args:
            contract_data_types: List of (type, variable) tuples from EDAM
            
        Returns:
            Tuple of (import_statements_string, parameter_code_list, assignment_code_list)
        """
        imports = []
        param_code = []
        assignment_code = []

        for dvar_type, dvar in contract_data_types:
            # Check if this is an external type (not in built-in types)
            # External types return import_data from type_mapping
            _, import_data = self.generator.type_mapping(dvar_type, "dummy", is_param=False)
            
            # Only add as constructor parameter if type is external (import_data is not empty)
            if import_data:
                var_name = dvar.var_name
                element_type = dvar_type
                element_name = var_name
                
                imports.append(f'import "./{element_type}.sol"')
                param_code.append(f"{element_type} __{element_name}")
                assignment_code.append(f"_{element_name} = __{element_name}")

        unique_imports = ";\n".join(set(imports)) + ";" if imports else ""
        return unique_imports, param_code, assignment_code
    
    def build_constructor_params(
        self,
        parameters: List[Any],
        participants: List[str],
        additional_params: List[str],
    ) -> str:
        """
        Build constructor parameter list string.
        Preserves the order of parameters from contract_data_types.
        
        Args:
            parameters: List of transition parameters
            participants: List of participant identifiers
            additional_params: Additional parameters from contract data types (ordered)
            
        Returns:
            Comma-separated parameter string
        """
        base_params = self.generator._generate_params(parameters, participants)
        # Preserve order from contract_data_types - remove duplicates while keeping order
        seen = set()
        ordered_additional = []
        for param in additional_params:
            if param not in seen:
                seen.add(param)
                ordered_additional.append(param)
        all_params = base_params + ordered_additional
        return ", ".join(all_params)
    
    def build_combined_conditions(self, guard_conditions: str) -> List[str]:
        """
        Build a list of combined conditions from guard conditions.
        
        Args:
            guard_conditions: Guard condition string
            
        Returns:
            List of condition strings
        """
        conditions = []
        if guard_conditions:
            conditions.append(str(guard_conditions))
        return conditions
    
    def build_role_assertion(
        self, role_updates: Any, caller: str, contract: str
    ) -> str:
        """
        Build role assertion require statement.
        
        Args:
            role_updates: The role updates to check
            caller: The caller identifier
            contract: The contract identifier
            
        Returns:
            Role assertion code string or empty string
        """
        role_checks_after = self.generator.parse_roles(role_updates, caller, contract)
        if role_checks_after:
            return f'assert({role_checks_after});\n\t'
        return ""
    
    def build_constructor_body(
        self,
        external_calls: List[str],
        assignment_code: List[str],
        solidity_assignments: List[str],
        role_updates: List[str],
        target_state: str,
        role_assertion: str,
    ) -> str:
        """
        Build the constructor body code.
        
        Args:
            external_calls: List of external call code strings
            assignment_code: List of assignment code strings
            solidity_assignments: List of Solidity assignment code strings
            role_updates: List of role update code strings
            target_state: Target state identifier
            role_assertion: Role assertion code string
            
        Returns:
            Complete constructor body as a string
        """
        state_update = f"_state = State.{target_state}; "
        all_statements = (
            assignment_code + solidity_assignments + role_updates + [state_update]
        )
        
        body_parts = []
        if external_calls:
            body_parts.append("\n\t".join(external_calls))
        
        body_parts.append(";\n\t\t".join(all_statements))
        
        if role_assertion:
            body_parts.append(role_assertion)
        
        return "\n\t".join(body_parts)
    
    def wrap_with_condition_check(
        self, conditions: List[str], body: str
    ) -> str:
        """
        Wrap body code with condition check. For constructors, always wrap with if statement
        even if guard is just 'true', and include else revert clause.
        
        Args:
            conditions: List of condition strings
            body: The body code to wrap
            
        Returns:
            Wrapped code string with if statement (with else revert) if conditions exist, otherwise just body
        """
        # For constructors, keep all conditions including 'true'
        # Don't filter out true values - we want to keep if(true) guards
        if not conditions:
            return body

        condition_string = " && ".join(conditions)
        return f"""if ({condition_string}) {{
            {body}
        }} else {{
            revert("{CONDITION_NOT_MET_MESSAGE}");
        }}"""
    
    def process_multiple_deploy_transitions(
        self,
        deploy_transitions: List[Transition],
        contract_name: str,
        contract_data_types: List[Tuple[str, Any]] = None
    ) -> Tuple[str, str]:
        """
        Process multiple deploy/start transitions with different guard conditions.
        Groups transitions by guard conditions and generates if-else blocks.
        
        Args:
            deploy_transitions: List of deploy/start transitions
            contract_name: The contract name
            contract_data_types: List of (type, variable) tuples from EDAM
            
        Returns:
            Tuple of (constructor_code, import_statements)
        """
        if not deploy_transitions:
            return "", ""
        
        # Process contract_data_types from EDAM to generate contract variables (only once)
        if contract_data_types:
            self._process_contract_data_types_for_variables(contract_data_types, contract_name)
        
        # Use first transition for shared constructor parameters and imports
        first_transition = deploy_transitions[0]
        
        # Process contract_data_types for constructor parameters (shared across all transitions)
        import_statements, param_code, assignment_code = (
            self.process_contract_data_types(contract_data_types) if contract_data_types else ("", [], [])
        )
        
        constructor_params = self.build_constructor_params(
            first_transition.parameters, first_transition.participants, param_code
        )
        
        # Check if any transition has external calls (for reentrancy modifier)
        has_external_calls = any(t.external_calls for t in deploy_transitions)
        reentrancy_modifier = "nonReentrant" if has_external_calls else ""
        
        # Group transitions by guard conditions
        guard_groups: Dict[str, List[Transition]] = {}
        
        for transition in deploy_transitions:
            # Serialize guard for grouping - parse guard to get string representation
            guard_str, _ = self.generator.parse_tree(
                transition.guard, transition.initiator, contract_name
            )
            # Use empty string if guard is empty/None for grouping
            guard_key = str(guard_str) if guard_str else ""
            
            if guard_key not in guard_groups:
                guard_groups[guard_key] = []
            guard_groups[guard_key].append(transition)
        
        # Process each guard group and build if-else blocks
        bodies = []
        for guard_key, group_transitions in guard_groups.items():
            # Process all transitions in this group (they share the same guard)
            # Use first transition from group for shared elements
            first_in_group = group_transitions[0]
            
            # Parse guard conditions
            guard_conditions, _ = self.generator.parse_tree(
                first_in_group.guard, first_in_group.initiator, contract_name
            )
            
            # Build constructor body for this group
            # If multiple transitions share the same guard, process them together
            group_bodies = []
            
            for transition in group_transitions:
                # Process assignments
                solidity_assignments, _ = self.generator._process_assignments_and_params(
                    transition.assignments,
                    contract_data_types if contract_data_types else [],
                    transition.initiator,
                    contract_name,
                )
                
                role_updates = self.generator.parse_roles_update(
                    transition.role_updates, transition.initiator, contract_name
                )
                
                role_assertion = self.build_role_assertion(
                    transition.role_updates, transition.initiator, contract_name
                )
                
                # Build body for this transition (without assignment_code - handled separately)
                if transition.external_calls:
                    try_catch_body = self.generator.try_catch_builder.build_try_catch_for_transition(
                        transition, contract_name
                    )
                    transition_body = try_catch_body
                else:
                    # No external calls, build body normally (without assignment_code)
                    transition_body = self.build_constructor_body(
                        [],
                        [],  # Don't include assignment_code here - handled at constructor start
                        solidity_assignments,
                        role_updates,
                        transition.target_state,
                        role_assertion,
                    )
                
                group_bodies.append(transition_body)
            
            # Combine bodies for transitions in this group
            combined_body = "\n\n\t\t".join(group_bodies)
            
            # Wrap with guard condition check
            combined_conditions = self.build_combined_conditions(guard_conditions)
            wrapped_body = self.wrap_with_condition_check(combined_conditions, combined_body)
            
            bodies.append(wrapped_body)
        
        # Prepend contract import assignments at the very beginning (before if-else blocks)
        # assignment_code contains assignments like "contractName = _contractName"
        if assignment_code:
            assignment_statements = "\t\t" + ";\n\t\t".join(assignment_code) + ";"
            # Combine all bodies with " else " to create if-else chain
            combined_bodies = f"{assignment_statements}\n\t\t" + " else ".join(bodies)
        else:
            # Combine all bodies with " else " to create if-else chain
            combined_bodies = " else ".join(bodies)
        
        constructor_code = SOLIDITY_CONSTRUCTOR_TEMPLATE.format(
            constructor_params=constructor_params,
            reentrancy_modifier=reentrancy_modifier,
            bodies=combined_bodies,
        )
        
        return constructor_code, import_statements

