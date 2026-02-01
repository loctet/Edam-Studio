import z3
from objects.Expressions import *

class Z3ExpressionParser:
    def __init__(self, data_vars: dict):
        """
        :param data_vars: A dictionary mapping variable names to their Z3 symbolic equivalents
        """
        self.data_vars = data_vars

    def parse(self, exp):
        """
        Recursively parse an expression node and return a z3 expression.
        """
        if isinstance(exp, And):
            return z3.And(self.parse(exp.left), self.parse(exp.right))

        elif isinstance(exp, Or):
            return z3.Or(self.parse(exp.left), self.parse(exp.right))

        elif isinstance(exp, Equal):
            return self.parse(exp.left) == self.parse(exp.right)

        elif isinstance(exp, NotEqual):
            return self.parse(exp.left) != self.parse(exp.right)

        elif isinstance(exp, LessThan):
            return self.parse(exp.left) < self.parse(exp.right)

        elif isinstance(exp, LessThanEqual):
            return self.parse(exp.left) <= self.parse(exp.right)

        elif isinstance(exp, GreaterThan):
            return self.parse(exp.left) > self.parse(exp.right)

        elif isinstance(exp, GreaterThanEqual):
            return self.parse(exp.left) >= self.parse(exp.right)

        elif isinstance(exp, Plus):
            return self.parse(exp.left) + self.parse(exp.right)

        elif isinstance(exp, Minus):
            return self.parse(exp.left) - self.parse(exp.right)

        elif isinstance(exp, Times):
            return self.parse(exp.left) * self.parse(exp.right)

        elif isinstance(exp, Divide):
            return self.parse(exp.left) / self.parse(exp.right)

        elif isinstance(exp, Val):
            if (exp.value in ["True", "False", True, False]) :
                return z3.BoolVal(exp.value)
            return z3.IntVal(exp.value) if isinstance(exp.value, int) else z3.BoolVal(exp.value)

        elif isinstance(exp, Dvar):
            return self.data_vars[exp.var_name]

        elif exp is True:
            return z3.BoolVal(True)
        elif exp is False:
            return z3.BoolVal(False)

        elif isinstance(exp, MapIndex):
            map_var = self.parse(exp.map_var)
            key = self.parse(exp.key)
            return map_var[key]  # if using z3.Array

        elif isinstance(exp, FuncCall):
            # Extend here with support for custom Z3-interpreted functions if needed
            raise NotImplementedError("Function calls in guards are not supported yet in Z3 parsing.")

        else:
            raise TypeError(f"Unsupported expression type: {type(exp)}")
