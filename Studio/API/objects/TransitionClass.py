
class Transition:
    def __init__(
        self,
        source_state,
        guard,
        external_calls,
        roles,
        participants,
        initiator,
        operation,
        parameters,
        assignments,
        role_updates,
        target_state,
    ):
        """
        Initialize a transition.
        
        :param source_state: State from where the transition begins.
        :param guard: Guard condition (Exp instance).
        :param roles: Role mapping for participants.
        :param participants: List of participants (e.g., ["user", "owner"]).
        :param initiator: Initiating participant (e.g., "msg.sender").
        :param operation: Operation name (e.g., "transfer").
        :param parameters: List of (type, Dvar) tuples for function parameters.
        :param assignments: List of (Dvar, Exp) tuples for state updates.
        :param role_updates: Role updates mapping.
        :param target_state: State to which the transition leads.
        """
        self.source_state = source_state
        self.guard = guard
        self.external_calls = external_calls
        self.roles = roles
        self.participants = participants
        self.initiator = initiator
        self.operation = operation
        self.parameters = parameters
        self.assignments = assignments
        self.role_updates = role_updates
        self.target_state = target_state

    def to_dict(self):
        """Convert the transition to a dictionary."""
        return {
            "source_state": self.source_state,
            "guard": str(self.guard),  # Assumes a string representation for Exp
            "roles": self.roles,
            "participants": self.participants,
            "initiator": self.initiator,
            "operation": self.operation,
            "parameters": [(ptype, str(pname)) for ptype, pname in self.parameters],
            "assignments": [(str(lhs), str(rhs)) for lhs, rhs in self.assignments],
            "role_updates": self.role_updates,
            "target_state": self.target_state,
            
        }

    def __repr__(self):
        return f"Transition({self.source_state} -> {self.target_state}, operation={self.operation})"
