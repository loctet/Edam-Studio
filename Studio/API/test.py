from itertools import permutations
import networkx as nx


class Exp:
    """Base class for expressions."""
    pass

# Arithmetic expressions
class Plus(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class Minus(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class Times(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class Equal(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class Divide(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class ListIndex(Exp):
    def __init__(self, lst, index, default):
        self.lst = lst
        self.index = index
        self.default = default

class MapIndex(Exp):
    def __init__(self, map_var, key, default):
        self.map_var = map_var
        self.key = key
        self.default = default

# Boolean expressions
class And(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class Or(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class Not(Exp):
    def __init__(self, operand):
        self.operand = operand

class GreaterThan(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class GreaterThanEqual(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right


class LessThan(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class LessThanEqual(Exp):
    def __init__(self, left, right):
        self.left = left
        self.right = right

# Value types
class Val(Exp):
    def __init__(self, value):
        self.value = value

class Ptp:
    def __init__(self, ptp):
        self.ptp = ptp
    
    def __str__(self):
        return f"{self.ptp}"  # Custom string representation for Ptp

class Pvar_a(Exp):
    def __init__(self, ptp_var):
        self.ptp_var = ptp_var

class Dvar(Exp):
    def __init__(self, var_name):
        self.var_name = var_name

# Function calls
class PtID(Exp):
    def __init__(self, ptp_var):
        self.ptp = ptp_var
        
    def getID(self, caller, contract_name):
       # print(self.ptp, caller, contract_name)
        if str(self.ptp) == str(caller):
            return "msg.sender"
        if str(self.ptp) == str(contract_name):
            return "address(this)"
        else :
            return self.ptp

class FuncCall(Exp):
    def __init__(self, operation, arguments):
        self.operation = operation
        self.arguments = arguments

class FuncCallEdamRead(Exp):
    def __init__(self, contract, expression):
        self.contract = contract
        self.expression = expression

class FuncCallEdamWrite(Exp):
    def __init__(self, contract, operation, ptp_params, data_params):
        self.contract = contract
        self.operation = operation
        self.ptp_params = ptp_params
        self.data_params = data_params



class Transition:
    def __init__(
        self,
        source_state,
        guard,
        roles,
        participants,
        initiator,
        operation,
        parameters,
        assignments,
        role_updates,
        target_state,
        contract_data_types=None  # Optional, only relevant for deploy transition
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
        :param contract_data_types: List of (type, Dvar) for contract initialization (only for deploy).
        """
        self.source_state = source_state
        self.guard = guard
        self.roles = roles
        self.participants = participants
        self.initiator = initiator
        self.operation = operation
        self.parameters = parameters
        self.assignments = assignments
        self.role_updates = role_updates
        self.target_state = target_state
        self.contract_data_types = contract_data_types

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
            "contract_data_types": [(ptype, str(pname)) for ptype, pname in self.contract_data_types]
            if self.contract_data_types
            else None,
        }

    def __repr__(self):
        return f"Transition({self.source_state} -> {self.target_state}, operation={self.operation})"

class EDAM:
    def __init__(
        self,
        name,
        states,
        transitions,
        final_states,
        initial_state,
        roles_list,
        participants_list,
        variables_list,
    ):
        self.name = name
        self.states = states
        self.transitions = transitions
        self.final_states = final_states
        self.initial_state = initial_state
        self.roles_list = roles_list
        self.participants_list = participants_list
        self.variables_list = variables_list

        # Create a directed graph to represent the EDAM
        self.graph = nx.DiGraph()
        for state in states:
            self.graph.add_node(state)
        for transition in transitions:
            self.graph.add_edge(transition.source_state, transition.target_state, object=transition)

    def to_dict(self):
        return {
            "name": self.name,
            "states": self.states,
            "transitions": [t.to_dict() for t in self.transitions],
            "final_states": self.final_states,
            "initial_state": self.initial_state,
            "roles_list": self.roles_list,
            "participants_list": self.participants_list,
            "variables_list": [str(var) for var in self.variables_list],
        }

    def __repr__(self):
        return f"EDAM(name={self.name}, states={len(self.states)}, transitions={len(self.transitions)})"

    def _generate_all_paths(self, transitions, source, paths=None):
        """
        Generate all paths starting from the source state by recursively removing transitions.

        :param transitions: List of transitions available.
        :param source: The source state.
        :param paths: Accumulated list of paths (used in recursion).
        :return: List of paths, where each path is a list of transitions.
        """
        if paths is None:
            paths = []

        # Find all outgoing transitions from the current source state
        outgoing_transitions = [t for t in transitions if t.source_state == source]

        # Stop recursion if no outgoing transitions
        if not outgoing_transitions:
            return [paths] if paths else []

        # Create new paths for each outgoing transition
        all_paths = []
        for transition in outgoing_transitions:
            # Remove the current transition from the list and create a new path
            remaining_transitions = [t for t in transitions if t != transition]
            new_path = paths + [transition]

            # Recursively explore paths from the target state of the current transition
            all_paths.extend(
                self._generate_all_paths(remaining_transitions, transition.target_state, new_path)
            )

        return all_paths

    def is_empty_role_free(self):
        """
        Check if the EDAM is empty-role free.

        :return: Tuple (is_empty_role_free, issues) where issues is a list of tuples (path, role) causing problems.
        """
        issues = []
        # Generate all paths starting from the "_" state
        all_paths = self._generate_all_paths(self.transitions, self.initial_state)

        for path in all_paths:
            for i, transition in enumerate(path):
                current_roles = transition.roles
                participants = transition.participants[:]
                participants.append(transition.initiator)

                for participant in participants:
                    participant_roles = current_roles.get(participant, {})

                    for role, mode in participant_roles.items():
                        if mode == "Top":
                            # Check if the role is activated in any prefix of the path
                            prefix_transitions = path[:i]
                            activated = any(
                                prefix_transition.role_updates.get(participant, {}).get(role) == "Top"
                                for prefix_transition in prefix_transitions
                            )

                            if not activated:
                                issues.append((path, role))

                # Check role_updates for "Bottom" mode
                for participant, updates in transition.role_updates.items():
                    for role, mode in updates.items():
                        if mode == "Bottom":
                            # Ensure there's a "Top" update for the role before this transition
                            prefix_transitions = [transition]
                            top_exists = any(
                                prefix_transition.roles.get(participant, {}).get(role) == "Top"
                                for prefix_transition in prefix_transitions
                            )
                            if not top_exists:
                                issues.append((path, f"Invalid Role {role} Update in Transition {transition}"))

                # Ensure all participants in role_updates are valid
                invalid_participants = [
                    participant
                    for participant in transition.role_updates
                    if participant not in participants
                ]
                for invalid in invalid_participants:
                    issues.append((path, f"Invalid Participant {invalid} in Transition {transition}"))

        return len(issues) == 0, issues

# Example usage
# Assuming `transitions`, `states`, and other attributes are defined and properly initialized.

edam_instance = EDAM(
name="AssetTransfer",
states=["S0", "S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9"],
transitions=[
         Transition(source_state="_", guard=Val(True), roles={"o": {"O": "Bottom", "B": "Bottom", "I": "Bottom", "A": "Bottom"}}, participants=[], initiator="o", operation="starts", parameters=[("int", Dvar("_price"))], assignments=[(Dvar("AskingPrice"), Dvar("_price")), (Dvar("OfferPrice"), Val(0))], role_updates={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S0", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}, "i": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}, "a": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=["i", "a"], initiator="b", operation="makeOffer", parameters=[("int", Dvar("_price"))], assignments=[(Dvar("OfferPrice"), Dvar("_price"))], role_updates={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}, "i": {"O": "Unknown", "B": "Unknown", "I": "Top", "A": "Unknown"}, "a": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Top"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S1"),
         Transition(source_state="S0", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S0", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="modify", parameters=[("string", Dvar("_description")), ("int", Dvar("_price"))], assignments=[(Dvar("AskingPrice"), Dvar("_price")), (Dvar("description"), Dvar("_description"))], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S1", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="modifyOffer", parameters=[("int", Dvar("_price"))], assignments=[(Dvar("OfferPrice"), Dvar("_price"))], role_updates={"b": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S1"),
         Transition(source_state="S1", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="reject", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S1", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="acceptOffer", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S2"),
         Transition(source_state="S1", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S1", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S2", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="reject", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S2", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S2", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S2", guard=Val(True), roles={"i": {"O": "Unknown", "B": "Unknown", "I": "Top", "A": "Unknown"}}, participants=[], initiator="i", operation="inspect", parameters=[], assignments=[], role_updates={"i": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S3"),
         Transition(source_state="S2", guard=Val(True), roles={"a": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Top"}}, participants=[], initiator="a", operation="MarkAppraised", parameters=[], assignments=[], role_updates={"a": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S7"),
         Transition(source_state="S3", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="reject", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S3", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S3", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S3", guard=Val(True), roles={"a": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Top"}}, participants=[], initiator="a", operation="MarkAppraised", parameters=[], assignments=[], role_updates={"a": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S4"),
         Transition(source_state="S4", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="reject", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S4", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S4", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S4", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="acceptOffer", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S5"),
         Transition(source_state="S4", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="accept", parameters=[], assignments=[], role_updates={"b": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S5", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S5", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="accept", parameters=[], assignments=[], role_updates={"b": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S6"),
         Transition(source_state="S7", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="reject", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S7", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S7", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S7", guard=Val(True), roles={"i": {"O": "Unknown", "B": "Unknown", "I": "Top", "A": "Unknown"}}, participants=[], initiator="i", operation="inspect", parameters=[], assignments=[], role_updates={"i": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S4"),
         Transition(source_state="S8", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="terminate", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S9"),
         Transition(source_state="S8", guard=Val(True), roles={"b": {"O": "Unknown", "B": "Top", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="b", operation="RescindOffer", parameters=[], assignments=[(Dvar("OfferPrice"), Val(0))], role_updates={"b": {"O": "Unknown", "B": "Bottom", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S0"),
         Transition(source_state="S8", guard=Val(True), roles={"o": {"O": "Top", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, participants=[], initiator="o", operation="accept", parameters=[], assignments=[], role_updates={"o": {"O": "Unknown", "B": "Unknown", "I": "Unknown", "A": "Unknown"}}, contract_data_types=[("string", Dvar("description")), ("int", Dvar("AskingPrice")), ("int", Dvar("OfferPrice"))],  target_state="S6")],
initial_state="_",
final_states=[],
roles_list=["O", "B", "I", "A"],
variables_list=[],
participants_list={}  # To be filled dynamically 
)
    
    

is_empty_role_free, issues = edam_instance.is_empty_role_free()
if is_empty_role_free:
    print("The EDAM is empty-role free.")
else:
    print("The EDAM is not empty-role free.")
    for path, role in issues:
        if "Invalid" in role:
            print(f"Issue: {role} in path: {[t.source_state + ' ' + t.operation  + ' -> ' + t.target_state for t in path]}")
        else:
            print(f"Issue found in path: {[t.source_state + ' ' + t.operation  + ' -> ' + t.target_state for t in path]} for role: {role}")