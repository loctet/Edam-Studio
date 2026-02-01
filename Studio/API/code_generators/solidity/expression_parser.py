from typing import List, Tuple, Any
from objects.Expressions import *

class SolidityExpressionParser:
    def __init__(self, edam=None):
        self.used_functions = set()
        self.global_edam_instance = edam
        self.contract_variables_with_type = {}

    def parse_tree(self, exp, caller="msg.sender", contract_name="address(this)", external_calls=None) -> Tuple[str, List[str]]:
        """
        Parse an expression tree and generate Solidity code.
        Returns a tuple of (guard_conditions, external_calls).
        """
        if external_calls is None:
            external_calls = []

        guard_conditions = []

        if isinstance(exp, And):
            guard_condition, calls = self.evaluate_and(exp, caller, contract_name, [])
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)

        elif isinstance(exp, Or):
            guard_condition, calls = self.evaluate_or(exp, caller, contract_name, external_calls)
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)

        elif isinstance(exp, Equal):
            guard_condition, calls = self.evaluate_equal(exp, caller, contract_name, external_calls)
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)
            #print(guard_condition, "Calls", calls)
            
        elif isinstance(exp, LessThan):
            guard_condition, calls = self.evaluate_less_than(exp, caller, contract_name, external_calls)
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)

        elif isinstance(exp, LessThanEqual):
            guard_condition, calls = self.evaluate_less_than_equal(exp, caller, contract_name, external_calls)
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)

        elif isinstance(exp, GreaterThan):
            guard_condition, calls = self.evaluate_greater_than(exp, caller, contract_name, external_calls)
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)

        elif isinstance(exp, GreaterThanEqual):
            guard_condition, calls = self.evaluate_greater_than_equal(exp, caller, contract_name, external_calls)
            guard_conditions.append(guard_condition)
            external_calls.extend(calls)

        elif isinstance(exp, Plus):
            guard_condition, calls = self.evaluate_plus(exp, caller, contract_name, [])
            return guard_condition, calls

        elif isinstance(exp, Minus):
            guard_condition, calls = self.evaluate_minus(exp, caller, contract_name, [])
            return guard_condition, calls

        elif isinstance(exp, Times):
            guard_condition, calls = self.evaluate_times(exp, caller, contract_name, [])
            return guard_condition, calls

        elif isinstance(exp, Divide):
            guard_condition, calls = self.evaluate_divide(exp, caller, contract_name, [])
            return guard_condition, calls

        elif isinstance(exp, Val):
            return str(self.evaluate_value(exp)), []

        elif isinstance(exp, Self):
            return f"address(this)", []

        elif isinstance(exp, Dvar):
            if exp.var_name in self.contract_variables_with_type:
                if self.contract_variables_with_type[exp.var_name] == "address":
                    return f"address({exp.var_name})", []
                if self.contract_variables_with_type[exp.var_name].endswith("Contract"):
                    return f"address({exp.var_name})", []
            return exp.var_name, []

        elif exp in [True, False]:
            return str(exp).lower(), []

        elif isinstance(exp, PtID):
            return self.evaluate_getId(exp, caller, contract_name)
            

        elif isinstance(exp, MapIndex):
            map_var = self.parse_tree(exp.map_var, caller, contract_name, external_calls)[0]
            key = self.parse_tree(exp.key, caller, contract_name, external_calls)[0]
            return f"{map_var}[{key}]", []

        elif isinstance(exp, FuncCall):
            return self.evaluate_func_call(exp, caller, contract_name, external_calls)

        elif isinstance(exp, FuncCallEdamWrite):
            _, calls = self.evaluate_func_call_edam_write(exp, caller, contract_name, external_calls)
            return "", calls

        return " && ".join(guard_conditions).replace(" && True", "").replace("True", "true").replace("False", "false"), external_calls

    def evaluate_value(self, exp):
        return str(exp.value).lower() if str(exp.value) in ["True", "False"] else str(exp.value)
        
    def evaluate_getId(self, exp, caller, contract_name):
        return str(exp.getID(caller, contract_name)), []
    
    def evaluate_and(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how AND expressions should be evaluated."""
        left_guard, left_calls = self.parse_tree(exp.left, caller, contract_name, external_calls)
        right_guard, right_calls = self.parse_tree(exp.right, caller, contract_name, external_calls)

        list_of_calls = list(set(left_calls + right_calls))
        if left_guard and right_guard:
            return f"({left_guard} && {right_guard})", list_of_calls
        
        return left_guard if left_guard else right_guard if right_guard else "", list_of_calls

    def evaluate_or(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how OR expressions should be evaluated."""
        left_guard, left_calls = self.parse_tree(exp.left, caller, contract_name, external_calls)
        right_guard, right_calls = self.parse_tree(exp.right, caller, contract_name, external_calls)
        list_of_calls = list(set(left_calls + right_calls))
        if left_guard and right_guard:
            return f"({left_guard} || {right_guard})", left_calls + right_calls
        
        return left_guard if left_guard else right_guard if right_guard else "", list_of_calls

    def evaluate_equal(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how Equal expressions should be evaluated."""
        left_guard, left_calls = self.parse_tree(exp.left, caller, contract_name, external_calls)
        right_guard, right_calls = self.parse_tree(exp.right, caller, contract_name, external_calls)
        
        #print("left guard", left_guard, "right guard", right_guard, "Left Calls", left_calls, "Right Calls", right_calls)
        return (
            f"{left_guard} == {right_guard}" if left_guard and right_guard else "",
            [left_calls[0] + f"{{ require({right_guard.lower()}); }} catch {{   require(!{right_guard.lower()}); }} "]
            if not right_calls and right_guard in ["True", "False", "true", "false"] else []
        )
    


    def evaluate_less_than(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how LessThan expressions should be evaluated."""
        left_guard = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right_guard = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"{left_guard} < {right_guard}", []

    def evaluate_less_than_equal(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how LessThanEqual expressions should be evaluated."""
        left_guard = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right_guard = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"{left_guard} <= {right_guard}", []

    def evaluate_greater_than(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how GreaterThan expressions should be evaluated."""
        left_guard = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right_guard = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"{left_guard} > {right_guard}", []

    def evaluate_greater_than_equal(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how GreaterThanEqual expressions should be evaluated."""
        left_guard = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right_guard = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"{left_guard} >= {right_guard}", []

    def evaluate_plus(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how Plus expressions should be evaluated."""
        left = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"({left} + {right})", []

    def evaluate_minus(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how Minus expressions should be evaluated."""
        left = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"({left} - {right})", []

    def evaluate_times(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how Times expressions should be evaluated."""
        left = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"({left} * {right})", []

    def evaluate_divide(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how Divide expressions should be evaluated."""
        left = self.parse_tree(exp.left, caller, contract_name, external_calls)[0]
        right = self.parse_tree(exp.right, caller, contract_name, external_calls)[0]
        return f"({left} / {right})", []

    def evaluate_func_call(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how function calls should be evaluated."""
        if exp.operation in ["update_map", "update_list", "append_list", "append", "append_lists", "update_nested_map"]:
            args = [self.parse_tree(arg, caller, contract_name, external_calls)[0] for arg in exp.arguments]
            if exp.operation == "update_map":
                return f"{args[0]}[{args[1]}] = {args[2]}", []
            elif exp.operation == "update_nested_map":
                return f"{args[0]}[{args[1]}][{args[2]}] = {args[3]}", []
            elif exp.operation == "update_list":
                return f"{args[0]}[{args[1]}] = {args[2]}", []
            elif exp.operation in ["append", "append_list"]:
                return f"{args[0]}.push({args[1]})", []
            elif exp.operation == "append_lists":
                return f"""for(uint _i = 0; _i < {args[1]}.length; _i+=1)
                    {args[0]}.push({args[1]}[_i])""", []
        else:
            if exp.operation in ["min", "max", "sum", "get_amount_out"]:
                self.used_functions.add(exp.operation)
            args_text = ", ".join([self.parse_tree(arg, caller, contract_name, external_calls)[0] for arg in exp.arguments])
            return f"{exp.operation}({args_text})", []

    def evaluate_func_call_edam_write(self, exp, caller, contract_name, external_calls):
        """Override this method to redefine how FuncCallEdamWrite expressions should be evaluated."""
        function_args = ", ".join([self.parse_tree(arg, caller, contract_name, external_calls)[0] for arg in exp.ptp_params] + 
                                  [self.parse_tree(arg, caller, contract_name, external_calls)[0] for arg in exp.data_params])
        call = f"try {exp.contract}.{exp.operation}({function_args}) "
        return "", [call]
