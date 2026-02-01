
function_snippets = {
    "sum": """
    // Function to calculate the sum of integers in an array
    function sum(uint[] memory numbers) internal pure returns (uint) {
        uint _total = 0;
        for (uint i = 0; i < numbers.length; i++) {
            _total += numbers[i];
        }
        return _total;
    }
    """,
    "min": """
    // Function to find the minimum value in an array
    function min(uint[] memory numbers) internal pure returns (uint) {
        require(numbers.length > 0, "Array cannot be empty");
        uint minimum = numbers[0];
        for (uint i = 1; i < numbers.length; i++) {
            if (numbers[i] < minimum) {
                minimum = numbers[i];
            }
        }
        return minimum;
    }

    //Min od 2 numbers
    function min(uint a, uint b) internal pure returns (uint) {
        if (a < b) 
            return a ;
        return  b;

    }
    """,
    "max": """
    // Function to find the maximum value in an array
    function max(uint[] memory numbers) internal pure returns (uint) {
        require(numbers.length > 0, "Array cannot be empty");
        uint maximum = numbers[0];
        for (uint i = 1; i < numbers.length; i++) {
            if (numbers[i] > maximum) {
                maximum = numbers[i];
            }
        }
        return maximum;
    }

    //Max od 2 numbers
    function max(uint a, uint b) internal pure returns (uint) {
        if (a > b) 
            return a ;
        return  b;

    }
    """,
    "get_amount_out": """
    // Function to calculate output amount given Uniswap-style reserves and input amount
    function get_amount_out(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut, 
        uint feePercent
    ) internal pure returns (uint) {
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        require(feePercent <= 1000, "Fee percent too high");

        uint multiplier = 1000;
        uint amountInWithFee = amountIn * (multiplier - feePercent);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * multiplier) + amountInWithFee;
        
        require(denominator > 0, "Denominator must be greater than zero");
        return numerator / denominator;
    }
    """,
    "roleSatisf": """
    // Function to check if a participant's roles satisfy role constraints
    // Checks: 1) participant_roles ∩ notrole_roles = ∅
    //         2) hasrole_roles ⊆ participant_roles
    function roleSatisf(
        address participant,
        Roles[] memory hasrole_roles,
        Roles[] memory notrole_roles
    ) internal view returns (bool) {
        // Check: participant_roles ∩ notrole_roles = ∅
        for (uint i = 0; i < notrole_roles.length; i++) {
            if (_permissions[participant][notrole_roles[i]]) {
                return false; // intersection not empty
            }
        }
        
        // Check: hasrole_roles ⊆ participant_roles
        for (uint i = 0; i < hasrole_roles.length; i++) {
            if (!_permissions[participant][hasrole_roles[i]]) {
                return false; // hasrole_roles not subset of participant_roles
            }
        }
        
        return true;
    }
    """

    
    
}

def generate_roles_overloads(parameter_counts: set) -> str:
    """
    Dynamically generate _roles function overloads based on actual usage.
    
    Args:
        parameter_counts: Set of integers representing parameter counts needed (e.g., {1, 2, 3})
        
    Returns:
        String containing the generated _roles overload functions
    """
    if not parameter_counts:
        return ""
    
    functions = []
    # Sort to generate functions in order
    sorted_counts = sorted(parameter_counts)
    
    for count in sorted_counts:
        if count <= 0:
            continue
        
        # Generate parameter list: "Roles r1, Roles r2, ..."
        params = ", ".join([f"Roles r{i+1}" for i in range(count)])
        
        # Generate assignment statements
        assignments = "\n        ".join([f"arr[{i}] = r{i+1};" for i in range(count)])
        
        function_code = f"""    function _roles({params}) internal pure returns (Roles[] memory arr) {{
        arr = new Roles[]({count});
        {assignments}
    }}"""
        
        functions.append(function_code)
    
    if functions:
        return "    // ----- Array Constructors -----\n" + "\n".join(functions)
    return ""

