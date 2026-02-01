SOLIDITY_CONTRACT_TEMPLATE = """
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

{imports}

contract {contract_name} {{
    {enum_states}
    {enum_role_list}
    {state_variable}
    {contract_variables}
    {non_reentrancy_variables}

    {constructor_code}

    {functions_code}

    {other_code}
}}
    """

SOLIDITY_CONSTRUCTOR_TEMPLATE = """
    constructor({constructor_params}) {reentrancy_modifier} {{
        {bodies}
    }}
    """

SOLIDITY_FUNCTION_TEMPLATE = """
    function {operation} ({params}) public {reentrancy_modifier} {{
        {bodies} else {{
            revert("Condition not met");
        }}
    }}
    """