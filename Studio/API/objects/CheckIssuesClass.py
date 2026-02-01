
class CheckIssues:
    def __init__(self, issues = []):
        self.issues = issues

    def to_dict(self):
        """Convert the transition to a dictionary."""
        return {
            "issues": self.issues,
        }
    
    def __str__(self, delimiter = "\n"):
        return self.__repr__(delimiter)
    
    def __repr__(self, delimiter = "\n"):
        repr = []
        for path, role in self.issues:
            if "Invalid" in role:
                repr.append(f"Issue: {role} in path: {[t.source_state + ' ' + t.operation  + ' -> ' + t.target_state for t in path]}")
            else:
                repr.append(f"Issue found in path: {[t.source_state + ' ' + t.operation  + ' -> ' + t.target_state for t in path]} for role: {role}")
        return delimiter.join(repr)
    
    def add_issue(self, issue):
        self.issues.append(issue)

    def check(self):
        return len(self.issues) == 0
    
    def get_issues(self):
        return self.issues  