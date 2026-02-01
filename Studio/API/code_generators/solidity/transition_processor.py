"""
Utilities for processing and grouping transitions.
"""

from typing import Dict, List, Tuple, Any

from objects.EdamClass import EDAM
from objects.TransitionClass import Transition
from code_generators.solidity.constants import DEPLOY_OPERATIONS, TRUE_VALUES
from code_generators.solidity.transition_grouping import TransitionGrouper
from code_generators.solidity.call_tree_builder import CallTreeBuilder


class TransitionProcessor:
    """Helper class for processing transitions."""
    
    def __init__(self, generator):
        """
        Initialize the transition processor.
        
        Args:
            generator: Reference to the SolidityGenerator instance
        """
        self.generator = generator
        self.grouper = TransitionGrouper(generator.parse_tree)
        self.tree_builder = CallTreeBuilder(generator)
        # Note: try_catch_builder will be set after generator initialization
        self.try_catch_builder = None
    
    def set_try_catch_builder(self, try_catch_builder):
        """Set the try-catch builder instance."""
        self.try_catch_builder = try_catch_builder
    
    def process_regular_transitions(
        self, edam: EDAM, contract_name: str
    ) -> Tuple[Dict[str, Dict[str, Any]], bool]:
        """
        Process all non-constructor transitions and group them by operation, then by (source_state, guard, roles).
        
        Args:
            edam: The EDAM instance
            contract_name: The contract name
            
        Returns:
            Tuple of (operation_map, has_external_calls_flag)
        """
        # First, collect all non-constructor transitions
        transitions = [
            t for t in edam.get("transitions")
            if t.operation.lower() not in DEPLOY_OPERATIONS
        ]
        
        # Group by operation first
        operation_groups: Dict[str, List[Transition]] = {}
        for transition in transitions:
            op = transition.operation
            if op not in operation_groups:
                operation_groups[op] = []
            operation_groups[op].append(transition)
        
        # Then group by (source_state, guard, roles) within each operation
        operation_map: Dict[str, Dict[str, Any]] = {}
        has_external_calls = False
        
        for operation, op_transitions in operation_groups.items():
            # Group transitions by (source_state, guard, roles)
            state_guard_roles_groups: Dict[Tuple[str, str, str], List[Transition]] = {}
            
            for transition in op_transitions:
                # Serialize guard for grouping
                guard_str = self.grouper.serialize_guard(
                    transition.guard, transition.initiator, contract_name
                )
                # Serialize roles structure for grouping
                roles_str = self.grouper.serialize_roles_structure(transition)
                key = (transition.source_state, guard_str, roles_str)
                
                if key not in state_guard_roles_groups:
                    state_guard_roles_groups[key] = []
                
                # Group transitions with the same state, guard, roles, and operation
                state_guard_roles_groups[key].append(transition)
            
            # Build if statements for each group
            params = ", ".join(
                self.generator._generate_params(op_transitions[0].parameters, op_transitions[0].participants)
            )
            
            bodies = []
            for (source_state, guard_str, roles_str), group_transitions in state_guard_roles_groups.items():
                # Build grouped if statement for this group
                if_statement = self.build_grouped_if_statement(
                    group_transitions, source_state, guard_str, contract_name
                )
                bodies.append(if_statement)
                
                # Check for external calls
                for t in group_transitions:
                    has_external_calls = has_external_calls or bool(t.external_calls)
            
            if operation not in operation_map:
                operation_map[operation] = {"params": params, "bodies": bodies}
            else:
                operation_map[operation]["bodies"].extend(bodies)
        
        return operation_map, has_external_calls
    
    def build_grouped_if_statement(
        self,
        transitions: List[Transition],
        source_state: str,
        guard_str: str,
        contract_name: str,
    ) -> str:
        """
        Build if statement for a group of transitions with the same source state and guard.
        
        All transitions in the group are placed within the same if statement,
        but each transition's try-catch blocks are generated separately.
        
        Args:
            transitions: List of transitions in the group
            source_state: The source state for all transitions
            guard_str: The serialized guard string
            contract_name: The contract name
            
        Returns:
            Complete if statement code string for the group
        """
        if not transitions:
            return ""
        
        # Use first transition for role checks and parameters (should be same for all)
        first_transition = transitions[0]
        
        # Build condition: state check + guard + role checks
        state_condition = f"_state == State.{source_state}"
        
        # Parse guard to get the actual guard condition code (without state check)
        guard_conditions, _ = self.generator.parse_tree(
            first_transition.guard, first_transition.initiator, contract_name
        )
        
        role_checks = self.generator.parse_roles(
            first_transition.roles, first_transition.initiator, contract_name
        )
        
        combined_conditions = [state_condition]
        # Always keep guard conditions, even if they evaluate to "true"
        if guard_conditions:
            combined_conditions.append(str(guard_conditions))
        
        if role_checks:
            combined_conditions.append(str(role_checks))
        
        # Filter out empty conditions and standalone "True"/"true" from role_checks,
        # but ALWAYS keep guard conditions even if they are "true"
        filtered_conditions = [state_condition]  # Always keep state condition
        
        # Always keep guard conditions, even if "true"
        if guard_conditions:
            filtered_conditions.append(str(guard_conditions))
        
        # Filter role checks (but not guard conditions)
        if role_checks and str(role_checks) not in TRUE_VALUES:
            filtered_conditions.append(str(role_checks))
        
        # Try to build call tree and generate optimized try-catch blocks
        # Only build tree if we have external calls
        has_external_calls = any(t.external_calls for t in transitions)
        
        if has_external_calls and self.tree_builder._can_build_tree(transitions, contract_name):
            # Build call tree and generate nested try-catch blocks from tree
            call_tree = self.tree_builder.build_call_tree(transitions, contract_name)
            if call_tree:
                # Get caller from first transition
                caller = first_transition.initiator if hasattr(first_transition, 'initiator') else "msg.sender"
                # Generate try-catch code from tree
                body = self.tree_builder.generate_try_catch_from_tree(
                    call_tree, contract_name, caller, indent_level=2
                )
            else:
                # Tree building failed, fall back to separate try-catch blocks
                transition_bodies = []
                for transition in transitions:
                    try_catch_block = self.try_catch_builder.build_try_catch_for_transition(transition, contract_name)
                    transition_bodies.append(try_catch_block)
                body = "\n\n\t\t".join(transition_bodies)
        else:
            # No external calls or cannot build tree - use separate try-catch blocks
            transition_bodies = []
            for transition in transitions:
                if transition.external_calls:
                    try_catch_block = self.try_catch_builder.build_try_catch_for_transition(transition, contract_name)
                    transition_bodies.append(try_catch_block)
                else:
                    # No external calls, just body
                    transition_body = self.try_catch_builder.build_transition_body_only(transition, contract_name)
                    transition_bodies.append(transition_body)
            body = "\n\n\t\t".join(transition_bodies)
        
        if not filtered_conditions:
            return body
        
        condition_string = " && ".join(filtered_conditions)
        return f"""if ({condition_string}) {{
            {body}
        }}"""

