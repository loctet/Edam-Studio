from objects.CheckIssuesClass import CheckIssues
import networkx as nx
from enum import Enum

class RoleStatus(Enum):
    TOP = 1
    BOTTOM = 2
    UNKNOWN = 3

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
        contract_data_types = None # Optional, only relevant for deploy transition  
    ):
        self.name = name
        self.states = states
        self.transitions = transitions
        self.final_states = final_states
        self.initial_state = initial_state
        self.roles_list = roles_list
        self.participants_list = participants_list
        self.variables_list = variables_list
        self.contract_data_types = contract_data_types
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
            "contract_data_types": [(ptype, str(pname)) for ptype, pname in self.contract_data_types]
            if self.contract_data_types
            else None,
        }
    def get(self, key):
        return self.__dict__[key]
    
    def __repr__(self):
        return f"EDAM(name={self.name}, states={self.states}, transitions={self.transitions})"

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
        issues = CheckIssues()
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
                                issues.add_issue((path, role))

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
                                issues.add_issue((path, f"Invalid: Role {role} Update in Transition {transition}"))

                # Ensure all participants in role_updates are valid
                invalid_participants = [
                    participant
                    for participant in transition.role_updates
                    if participant not in participants
                ]
                for invalid in invalid_participants:
                    issues.add_issue((path, f"Invalid: Participant {invalid} in Transition {transition}"))

        return {"check": issues.check(), "issues": "<table class='table table-striped table-bordered table-hover'><tbody><tr><td>" + issues.__str__("</td><tr><td>") + "</td></tr></tbody></table>"}


