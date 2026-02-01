
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

class NotEqual(Exp):
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

class Self(Exp):
    def __init__(self):
        pass

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
        
    def getID(self, caller, contract_name, plateform = "solidity"):
        if str(self.ptp) == str(caller) and plateform == "solidity":
            return "msg.sender" 
        
        if str(self.ptp) == str(caller) and plateform == "move":
            return "_signerAddress"
        
        if str(self.ptp) == str(contract_name) and plateform == "solidity":
            return "address(this)"
        if str(self.ptp) == str(contract_name) and plateform == "move":
             return "address(this)"
        return str(self.ptp)

class FuncCall(Exp):
    def __init__(self, operation, arguments):
        self.operation = operation
        self.arguments = arguments

class FuncCallEdamRead(Exp):
    def __init__(self, contract, expression):
        self.contract = f"_{contract}"
        self.expression = expression

class FuncCallEdamWrite(Exp):
    def __init__(self, contract, operation, ptp_params, data_params):
        self.contract = f"_{contract}"
        self.operation = operation
        self.ptp_params = ptp_params
        self.data_params = data_params

