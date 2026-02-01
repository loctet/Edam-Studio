from typing import Dict, List, Set

class SolidityRoleHandler:
    def __init__(self):
        """Initialize role handler with tracking for _roles parameter counts."""
        self._roles_parameter_counts: Set[int] = set()
    
    def get_participant_variable(self, participant: str, caller: str, contract: str) -> str:
        if participant in ["user", caller]:
            return "msg.sender"
        elif participant in [contract]:
            return "address(this)"
        else:
            return participant
    
    def get_roles_parameter_counts(self) -> Set[int]:
        """Get the set of parameter counts used in _roles calls."""
        return self._roles_parameter_counts

    """
    def parse_roles(self, rho: Dict, caller: str, contract: str) -> str:
        ""
        Parse Pi and return Solidity conditions for role checks.
        ""
        conditions = []
        for participant, roles in pi.items():
            for role, mode in roles.items():
                if mode == "Top":
                    conditions.append(
                        f"_permissions[{self.get_participant_variable(participant, caller, contract)}][Roles.{role}]"
                    )
                elif mode == "Bottom":
                    conditions.append(
                        f"!_permissions[{self.get_participant_variable(participant, caller, contract)}][Roles.{role}]"
                    )
        return " && ".join(conditions)
    """

    def parse_roles(self, rho: Dict, caller: str, contract: str) -> str:
        """
        Parse Pi and return Solidity conditions for role checks using roleSatisf.
        """
        # Generate individual function calls for each participant
        conditions = []
        
        for participant, roles in rho.items():
            participant_var = self.get_participant_variable(participant, caller, contract)
            
            # Get hasrole and notrole roles for this specific participant
            hasrole_roles = []
            notrole_roles = []
            
            for role, mode in roles.items():
                if mode == "Top":
                    hasrole_roles.append(f"Roles.{role}")
                elif mode == "Bottom":
                    notrole_roles.append(f"Roles.{role}")
            
            # Track parameter counts for _roles calls
            if hasrole_roles:
                self._roles_parameter_counts.add(len(hasrole_roles))
            if notrole_roles:
                self._roles_parameter_counts.add(len(notrole_roles))
            
            # Generate function call for this participant
            hasrole_array = f"_roles({', '.join(hasrole_roles)})" if hasrole_roles else "new Roles [] (0)"
            notrole_array = f"_roles({', '.join(notrole_roles)})" if notrole_roles else "new Roles [] (0)"
            
            if hasrole_roles or notrole_roles:
                conditions.append(f"roleSatisf({participant_var}, {hasrole_array}, {notrole_array})")
        
        return " && ".join(conditions)

    def parse_roles_update(self, rho_prime: Dict, caller: str, contract: str) -> List[str]:
        """
        Generate Solidity assignments for role updates.
        """
        assignments = []
        for participant, roles in rho_prime.items():
            for role, mode in roles.items():
                if mode == "Top":
                    assignments.append(
                        f"_permissions[{self.get_participant_variable(participant, caller, contract)}][Roles.{role}] = true"
                    )
                elif mode == "Bottom":
                    assignments.append(
                        f"_permissions[{self.get_participant_variable(participant, caller, contract)}][Roles.{role}] = false"
                    )
        return assignments 