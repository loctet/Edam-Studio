"""
Utilities for building call trees and generating optimized nested try-catch blocks.
"""

from typing import List, Optional, Tuple, Any, Dict
from objects.Expressions import Equal, FuncCallEdamWrite, Val
from objects.TransitionClass import Transition


class CallTreeNode:
    """Represents a node in the call tree."""
    
    def __init__(self, call_signature: Tuple[str, str], call_expr: Equal):
        """
        Initialize a call tree node.
        
        Args:
            call_signature: Tuple of (contract, operation)
            call_expr: The original Equal expression containing the call
        """
        self.call_signature = call_signature  # (contract, operation)
        self.call_expr = call_expr
        self.success_branch: Optional[CallTreeNode] = None  # Can be CallTreeNode or Transition
        self.failure_branch: Optional[Transition] = None  # Can be Transition or list of Transitions
        self.success_transitions: List[Transition] = []  # Transitions that expect this call to succeed
        self.failure_transitions: List[Transition] = []  # Transitions that expect this call to fail
        
    def is_leaf(self) -> bool:
        """Check if this is a leaf node (no children)."""
        return self.success_branch is None and self.failure_branch is None
    
    def has_success_branch(self) -> bool:
        """Check if this node has a success branch."""
        return self.success_branch is not None or len(self.success_transitions) > 0
    
    def has_failure_branch(self) -> bool:
        """Check if this node has a failure branch."""
        return self.failure_branch is not None or len(self.failure_transitions) > 0


class CallTreeBuilder:
    """Helper class for building call trees and generating try-catch code."""
    
    def __init__(self, generator):
        """
        Initialize the call tree builder.
        
        Args:
            generator: Reference to the SolidityGenerator instance
        """
        self.generator = generator
    
    def _get_call_signature(self, call_expr: Equal) -> Optional[Tuple[str, str]]:
        """
        Extract (contract, operation) signature from a call expression.
        
        Args:
            call_expr: Equal expression with FuncCallEdamWrite
            
        Returns:
            Tuple of (contract, operation) or None if not valid
        """
        if isinstance(call_expr, Equal) and isinstance(call_expr.left, FuncCallEdamWrite):
            call_obj = call_expr.left
            return (call_obj.contract, call_obj.operation)
        return None
    
    def _normalize_call_sequence(self, transition: Transition) -> List[Tuple[str, str]]:
        """
        Extract normalized call sequence (contract, operation) pairs from transition.
        
        Args:
            transition: The transition to extract calls from
            
        Returns:
            List of (contract, operation) tuples
        """
        sequence = []
        for call_expr in transition.external_calls:
            signature = self._get_call_signature(call_expr)
            if signature:
                sequence.append(signature)
        return sequence
    
    def _can_build_tree(self, transitions: List[Transition], contract_name: str) -> bool:
        """
        Check if transitions can form a call tree.
        
        Tree can be built if:
        - All transitions have external calls
        - They share call sequences where calls have same (contract, operation)
        - Sequences can differ by success/failure expectations
        
        Args:
            transitions: List of transitions to check
            contract_name: Contract name (for context)
            
        Returns:
            True if tree can be built, False otherwise
        """
        if not transitions:
            return False
        
        # All transitions must have external calls
        if not all(t.external_calls for t in transitions):
            return False
        
        # Get call sequences for all transitions
        sequences = [self._normalize_call_sequence(t) for t in transitions]
        
        # Check if sequences share prefixes (can form a tree)
        # For tree building, we need sequences that share common prefixes
        # For example: [c1.g, c2.f], [c1.g, c2.f], [c1.g] can form a tree
        if len(sequences) < 2:
            return True  # Single transition can always be a tree
        
        # Check if all sequences share at least the first call signature
        first_sigs = [seq[0] if seq else None for seq in sequences]
        if not all(sig == first_sigs[0] for sig in first_sigs if first_sigs[0] is not None):
            return False
        
        # Additional check: sequences should be compatible (share prefixes)
        # This is a simplified check - in practice, we need to ensure sequences
        # can be arranged into a tree structure
        return True
    
    def build_call_tree(
        self, transitions: List[Transition], contract_name: str
    ) -> Optional[CallTreeNode]:
        """
        Build a call tree from transitions.
        
        Args:
            transitions: List of transitions with external calls
            contract_name: Contract name for context
            
        Returns:
            Root CallTreeNode or None if tree cannot be built
        """
        if not self._can_build_tree(transitions, contract_name):
            return None
        
        if not transitions:
            return None
        
        # Build tree recursively
        return self._build_tree_recursive(transitions, 0)
    
    def _build_tree_recursive(
        self, transitions: List[Transition], depth: int
    ) -> Optional[CallTreeNode]:
        """
        Recursively build tree structure from transitions.
        
        The tree groups transitions by their call sequences. At each depth,
        transitions with the same (contract, operation) share a node, but
        branch based on whether they expect the call to succeed or fail.
        
        Args:
            transitions: List of transitions to process
            depth: Current depth in call sequence
            
        Returns:
            CallTreeNode representing this level, or None
        """
        if not transitions:
            return None
        
        # Filter out transitions that have no more calls at this depth
        active_transitions = [t for t in transitions if depth < len(t.external_calls)]
        
        if not active_transitions:
            # All transitions complete - this shouldn't happen, but handle gracefully
            return None
        
        # Group transitions by their call signature at current depth
        # All transitions at this depth must have the same (contract, operation)
        # but can differ in expected success/failure
        first_call = active_transitions[0].external_calls[depth]
        signature = self._get_call_signature(first_call)
        
        if not signature:
            return None
        
        # Verify all transitions have the same call signature at this depth
        for transition in active_transitions:
            call_expr = transition.external_calls[depth]
            trans_sig = self._get_call_signature(call_expr)
            if trans_sig != signature:
                # Different call signatures - cannot form a single tree
                return None
        
        # Create node for this call
        node = CallTreeNode(signature, first_call)
        
        # Separate transitions by their expectation for this call
        # Transitions expecting success continue in the try block (success branch)
        # Transitions expecting failure continue in the catch block (failure branch)
        success_expecting = []  # Transitions expecting this call to succeed
        failure_expecting = []  # Transitions expecting this call to fail
        
        for transition in active_transitions:
            call_expr = transition.external_calls[depth]
            expected_success = (
                call_expr.right.value 
                if isinstance(call_expr.right, Val) 
                else call_expr.right
            )
            if not isinstance(expected_success, bool):
                expected_success = str(expected_success).lower() == "true"
            
            if expected_success:
                success_expecting.append(transition)
            else:
                failure_expecting.append(transition)
        
        # Process success branch (try block - call succeeds)
        # Transitions that expect success continue from here
        if success_expecting:
            # Separate transitions that continue vs. complete
            transitions_with_more = [
                t for t in success_expecting 
                if len(t.external_calls) > depth + 1
            ]
            transitions_complete = [
                t for t in success_expecting 
                if len(t.external_calls) == depth + 1
            ]
            
            if transitions_with_more:
                # Some transitions continue - build next level recursively
                next_node = self._build_tree_recursive(
                    transitions_with_more, depth + 1
                )
                if next_node:
                    node.success_branch = next_node
            
            # Handle complete transitions (they finish here)
            if transitions_complete:
                node.success_transitions = transitions_complete
                # If no recursive node and single transition, store as direct branch
                if not node.success_branch and len(transitions_complete) == 1:
                    node.success_branch = transitions_complete[0]
        
        # Process failure branch (catch block - call fails)
        # Transitions that expect failure continue from here
        if failure_expecting:
            # Transitions expecting failure typically complete here
            # (if a call fails as expected, we don't continue with more calls)
            node.failure_transitions = failure_expecting
            if len(failure_expecting) == 1:
                node.failure_branch = failure_expecting[0]
        
        return node
    
    def generate_try_catch_from_tree(
        self,
        call_tree: CallTreeNode,
        contract_name: str,
        caller: str,
        indent_level: int = 2
    ) -> str:
        """
        Generate Solidity try-catch code from call tree.
        
        Args:
            call_tree: Root CallTreeNode
            contract_name: Contract name
            caller: Caller identifier
            indent_level: Base indentation level
            
        Returns:
            Generated Solidity try-catch code string
        """
        if call_tree is None:
            return ""
        
        # Generate indentation string
        indent = "\t" * indent_level
        inner_indent = "\t" * (indent_level + 1)
        
        # Get call code
        call_obj = call_tree.call_expr.left
        _, call_strings = self.generator.expression_parser.evaluate_func_call_edam_write(
            call_obj, caller, contract_name, []
        )
        
        if not call_strings:
            return ""
        
        call_code = call_strings[0].replace("try ", "").strip()
        
        # Generate success branch code
        success_code = ""
        if isinstance(call_tree.success_branch, CallTreeNode):
            # Recursive case: more nested try-catch
            success_code = self.generate_try_catch_from_tree(
                call_tree.success_branch, contract_name, caller, indent_level + 1
            )
        elif isinstance(call_tree.success_branch, Transition):
            # Leaf case: generate transition body
            success_code = self._generate_transition_body(
                call_tree.success_branch, contract_name, indent_level + 1
            )
        elif call_tree.success_transitions:
            # Multiple transitions complete here - generate first one
            # (In practice, this should be handled differently if multiple are possible)
            success_code = self._generate_transition_body(
                call_tree.success_transitions[0], contract_name, indent_level + 1
            )
        
        # Generate failure branch code
        failure_code = ""
        if isinstance(call_tree.failure_branch, Transition):
            # Leaf case: generate transition body
            failure_code = self._generate_transition_body(
                call_tree.failure_branch, contract_name, indent_level + 1
            )
        elif call_tree.failure_transitions:
            # Multiple transitions with failure - generate first one
            failure_code = self._generate_transition_body(
                call_tree.failure_transitions[0], contract_name, indent_level + 1
            )
        
        # Build try-catch block
        # The structure is:
        # try { call; [what happens if call succeeds] } catch { [what happens if call fails] }
        # 
        # The branches are based on actual outcomes:
        # - success_code: what happens when call succeeds (contains transitions that continue from success)
        # - failure_code: what happens when call fails (contains transitions that continue from failure)
        # 
        # Note: We don't check expectations here - the tree structure already represents
        # which transitions continue from success vs failure branches
        
        # If we have success_code, it means some transitions continue from success
        # If we have failure_code, it means some transitions continue from failure
        
        # Default revert messages if branches are empty
        if not success_code:
            # No transitions continue from success - this shouldn't happen if tree is built correctly
            success_code = 'revert("Unexpected: no success branch");'
        
        if not failure_code:
            # No transitions continue from failure - add revert
            failure_code = 'revert("Expected external call to succeed");'
        
        # Generate try-catch block
        return f"""try {call_code} {{
{inner_indent}{success_code}
{indent}}} catch {{
{inner_indent}{failure_code}
{indent}}}"""
    
    def _generate_transition_body(
        self, transition: Transition, contract_name: str, indent_level: int
    ) -> str:
        """
        Generate transition body code (assignments, role updates, state change).
        
        Args:
            transition: The transition to generate body for
            contract_name: Contract name
            indent_level: Indentation level
            
        Returns:
            Transition body code string
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
        
        if len(all_statements) == 1:
            statements_code = all_statements[0]
        else:
            statements_code = (";\n" + indent).join(all_statements)
        
        if role_assertion:
            statements_code += "\n" + indent + role_assertion.strip()
        
        return statements_code

