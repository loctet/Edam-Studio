"""
Utilities for grouping transitions based on guards and external calls.
"""

from typing import Any, Dict, List, Optional, Tuple

from objects.Expressions import Equal, FuncCallEdamWrite
from objects.TransitionClass import Transition


class TransitionGrouper:
    """Helper class for grouping transitions."""
    
    def __init__(self, parse_tree_func):
        """
        Initialize the transition grouper.
        
        Args:
            parse_tree_func: Function to parse expressions (from generator)
        """
        self.parse_tree = parse_tree_func
    
    def serialize_guard(self, guard: Any, caller: str, contract_name: str) -> str:
        """
        Serialize guard expression to string for comparison.
        
        Args:
            guard: The guard expression (without state check)
            caller: The caller identifier
            contract_name: The contract name identifier
            
        Returns:
            Serialized guard as string
        """
        guard_str, _ = self.parse_tree(guard, caller, contract_name)
        return guard_str
    
    def guards_are_equivalent(
        self, g1: Any, g2: Any, caller: str, contract_name: str
    ) -> bool:
        """
        Compare two guards syntactically using string serialization.
        
        Args:
            g1: First guard expression
            g2: Second guard expression
            caller: The caller identifier
            contract_name: The contract name identifier
            
        Returns:
            True if guards are syntactically equivalent, False otherwise
        """
        guard1_str = self.serialize_guard(g1, caller, contract_name)
        guard2_str = self.serialize_guard(g2, caller, contract_name)
        return guard1_str == guard2_str
    
    def get_call_signature(
        self, call: Any, contract_name: str
    ) -> Optional[Tuple[str, str, str]]:
        """
        Extract signature from external call for comparison.
        
        Args:
            call: The external call (Equal expression with FuncCallEdamWrite)
            contract_name: The contract name identifier
            
        Returns:
            Tuple of (contract, operation, signature) or None if not a valid call
        """
        # external_calls contains Equal expressions where:
        # left is FuncCallEdamWrite
        # right is Val(True) or Val(False)
        if isinstance(call, Equal):
            if isinstance(call.left, FuncCallEdamWrite):
                call_obj = call.left
                # Create a normalized signature based on contract and operation
                # We don't compare parameters here, just operation
                return (call_obj.contract, call_obj.operation, "signature")
        return None
    
    def calls_match_by_operation(
        self, call1: Any, call2: Any, contract_name: str
    ) -> bool:
        """
        Check if two external calls have the same operation (ignoring expected boolean).
        
        Args:
            call1: First external call expression
            call2: Second external call expression
            contract_name: The contract name identifier
            
        Returns:
            True if calls have the same operation, False otherwise
        """
        sig1 = self.get_call_signature(call1, contract_name)
        sig2 = self.get_call_signature(call2, contract_name)
        
        if sig1 is None or sig2 is None:
            return False
        
        # Compare contract and operation (ignoring the third element which is just "signature")
        return sig1[0] == sig2[0] and sig1[1] == sig2[1]
    
    def can_group_transitions(
        self, t1: Transition, t2: Transition, contract_name: str
    ) -> bool:
        """
        Check if two transitions can be grouped.
        
        Transitions can be grouped if they have:
        - Same source state
        - Same operation
        - Equivalent guards
        - At least one external call with matching operation (may have different expectations)
        
        Args:
            t1: First transition
            t2: Second transition
            contract_name: The contract name identifier
            
        Returns:
            True if transitions can be grouped, False otherwise
        """
        # Check source state
        if t1.source_state != t2.source_state:
            return False
        
        # Check operation
        if t1.operation != t2.operation:
            return False
        
        # Check guards are equivalent
        if not self.guards_are_equivalent(
            t1.guard, t2.guard, t1.initiator, contract_name
        ):
            return False
        
        # Check if they share at least one external call with matching operation
        for call1 in t1.external_calls:
            for call2 in t2.external_calls:
                if self.calls_match_by_operation(call1, call2, contract_name):
                    return True
        
        # If both have no external calls or no matching calls, they can still be grouped
        # if they share the same guard, state, and operation
        return len(t1.external_calls) == 0 and len(t2.external_calls) == 0
    
    def normalize_roles_structure(self, transition: Transition) -> Tuple[Dict[str, str], List[Dict[str, str]]]:
        """
        Normalize roles structure by extracting role mappings without participant names.
        
        Args:
            transition: The transition to extract roles from
            
        Returns:
            Tuple of (initiator_roles_dict, participants_roles_list)
            - initiator_roles_dict: Dict mapping role names to modes (e.g., {"R1": "Top", "R2": "Bottom"})
            - participants_roles_list: List of role dicts, one per participant in order
        """
        roles = transition.roles if transition.roles else {}
        
        # Get initiator's roles (normalized - just the role mapping, not participant name)
        initiator_roles = roles.get(transition.initiator, {})
        # Copy the dict to avoid mutating the original
        initiator_roles_normalized = dict(initiator_roles) if initiator_roles else {}
        
        # Get participants' roles in order
        participants_roles_list = []
        if transition.participants:
            for participant in transition.participants:
                participant_roles = roles.get(participant, {})
                # Copy the dict to avoid mutating the original
                participant_roles_normalized = dict(participant_roles) if participant_roles else {}
                participants_roles_list.append(participant_roles_normalized)
        
        return (initiator_roles_normalized, participants_roles_list)
    
    def serialize_roles_structure(self, transition: Transition) -> str:
        """
        Serialize roles structure to a string for use in grouping keys.
        
        This normalizes roles by structure (roles and modalities) rather than
        participant names, so transitions with different participant names but
        same role structures can be grouped together.
        
        Args:
            transition: The transition to serialize roles for
            
        Returns:
            String representation of the roles structure
        """
        initiator_roles, participants_roles = self.normalize_roles_structure(transition)
        
        # Serialize initiator roles (sorted for consistency)
        initiator_str = "|".join(f"{role}:{mode}" for role, mode in sorted(initiator_roles.items())) if initiator_roles else ""
        
        # Serialize participants roles (in order, sorted for consistency)
        participants_str = ";".join(
            "|".join(f"{role}:{mode}" for role, mode in sorted(part_roles.items())) if part_roles else ""
            for part_roles in participants_roles
        )
        
        return f"initiator:{initiator_str};participants:{participants_str}"
    
    def roles_structures_are_equivalent(self, t1: Transition, t2: Transition) -> bool:
        """
        Check if two transitions have equivalent roles structures.
        
        Two transitions have equivalent roles structures if:
        - Their initiators have the same roles (ignoring participant names)
        - Their participants in the same positions have the same roles (ignoring participant names)
        
        Args:
            t1: First transition
            t2: Second transition
            
        Returns:
            True if roles structures are equivalent, False otherwise
        """
        initiator_roles1, participants_roles1 = self.normalize_roles_structure(t1)
        initiator_roles2, participants_roles2 = self.normalize_roles_structure(t2)
        
        # Check initiator roles are the same
        if initiator_roles1 != initiator_roles2:
            return False
        
        # Check participants roles are the same (in order)
        if len(participants_roles1) != len(participants_roles2):
            return False
        
        for part_roles1, part_roles2 in zip(participants_roles1, participants_roles2):
            if part_roles1 != part_roles2:
                return False
        
        return True

