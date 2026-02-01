"""
Utilities for building try-catch blocks for transitions with external calls.
"""

from objects.Expressions import Equal, FuncCallEdamWrite, Val
from objects.TransitionClass import Transition


class TryCatchBuilder:
    """Helper class for building try-catch blocks."""
    
    def __init__(self, generator):
        """
        Initialize the try-catch builder.
        
        Args:
            generator: Reference to the SolidityGenerator instance
        """
        self.generator = generator
    
    def build_try_catch_for_transition(
        self, transition: Transition, contract_name: str
    ) -> str:
        """
        Build nested try-catch blocks for a single transition based on external calls.
        
        For each external call:
        - If expected true: try { call; proceed } catch { revert("Expected success") }
        - If expected false: try { call; revert("Expected failure") } catch { proceed }
        
        Args:
            transition: The transition to process
            contract_name: The contract name
            
        Returns:
            Nested try-catch code string for the transition
        """
        if not transition.external_calls:
            # No external calls, just return the transition body
            return self.build_transition_body_only(transition, contract_name)
        
        # Build transition body (assignments, role updates, state change)
        role_updates = self.generator.parse_roles_update(
            transition.role_updates, transition.initiator, contract_name
        )
        
        solidity_assignments, _ = self.generator._process_assignments_and_params(
            transition.assignments,
            transition.parameters,
            transition.initiator,
            contract_name,
        )
        
        role_assertion = self.generator._build_role_assertion(
            transition.role_updates, transition.initiator, contract_name
        )
        
        state_update = f"_state = State.{transition.target_state};"
        all_statements = solidity_assignments + role_updates + [state_update]
        # Indentation: inside nested try-catch, so need multiple tabs
        statements_code = ";\n\t\t\t".join(all_statements)
        if role_assertion:
            statements_code += "\n\t\t\t" + role_assertion.strip()
        
        # Build nested try-catch blocks from left to right (outermost to innermost)
        # Start with the transition body
        current_block = statements_code
        
        # Process external calls in reverse order (rightmost/innermost first) to build from inside out
        for call_expr in reversed(transition.external_calls):
            if isinstance(call_expr, Equal) and isinstance(call_expr.left, FuncCallEdamWrite):
                call_obj = call_expr.left
                expected_success = call_expr.right.value if isinstance(call_expr.right, Val) else call_expr.right
                
                # Parse the call to get Solidity code
                # The parser returns "try contract.operation(...) " format
                _, call_strings = self.generator.expression_parser.evaluate_func_call_edam_write(
                    call_obj, transition.initiator, contract_name, []
                )
                
                if call_strings:
                    # Extract the actual call without "try" prefix
                    # Parser returns "try contract.operation(...) " format
                    call_code = call_strings[0].replace("try ", "").strip()
                    
                    if expected_success:
                        # Expected to succeed (true): 
                        # try { call; [current_block with next/body] } catch { revert }
                        # If call succeeds, proceed with next/body in try block
                        # If call fails (unexpected), revert in catch block
                        current_block = f"""try {call_code} {{
                    {current_block}
                }} catch {{
                    revert("Expected external call to succeed");
                }}"""
                    else:
                        # Expected to fail (false/bar):
                        # try { call; revert } catch { [current_block with next/body] }
                        # If call succeeds (unexpected), revert in try block
                        # If call fails (as expected), continue with next/body in catch block
                        # NOTE: The body/next element goes in catch, NOT in try!
                        current_block = f"""try {call_code} {{
                    revert("Expected external call to fail");
                }} catch {{
                    {current_block}
                }}"""
        
        return current_block
    
    def build_transition_body_only(
        self, transition: Transition, contract_name: str
    ) -> str:
        """
        Build transition body without external calls (assignments, role updates, state change).
        
        Args:
            transition: The transition to process
            contract_name: The contract name
            
        Returns:
            Transition body code string
        """
        role_updates = self.generator.parse_roles_update(
            transition.role_updates, transition.initiator, contract_name
        )
        
        solidity_assignments, _ = self.generator._process_assignments_and_params(
            transition.assignments,
            transition.parameters,
            transition.initiator,
            contract_name,
        )
        
        role_assertion = self.generator._build_role_assertion(
            transition.role_updates, transition.initiator, contract_name
        )
        
        state_update = f"_state = State.{transition.target_state};"
        all_statements = solidity_assignments + role_updates + [state_update]
        statements_code = ";\n\t\t".join(all_statements)
        
        if role_assertion:
            statements_code += "\n\t\t" + role_assertion.strip()
        
        return statements_code
    
    def _generate_transition_body(
        self, transition: Transition, contract_name: str, indent_level: int
    ) -> str:
        """
        Generate transition body code (assignments, role updates, state change).
        Helper method for generating transition bodies with custom indentation.
        
        Args:
            transition: The transition to generate body for
            contract_name: Contract name
            indent_level: Indentation level (number of tabs)
            
        Returns:
            Transition body code string with proper indentation
        """
        indent = "\t" * indent_level
        
        role_updates = self.generator.parse_roles_update(
            transition.role_updates, transition.initiator, contract_name
        )
        
        solidity_assignments, _ = self.generator._process_assignments_and_params(
            transition.assignments,
            transition.parameters,
            transition.initiator,
            contract_name,
        )
        
        role_assertion = self.generator._build_role_assertion(
            transition.role_updates, transition.initiator, contract_name
        )
        
        state_update = f"_state = State.{transition.target_state};"
        all_statements = solidity_assignments + role_updates + [state_update]
        statements_code = ";\n" + indent.join(all_statements)
        
        if role_assertion:
            statements_code += "\n" + indent + role_assertion.strip()
        
        return statements_code

