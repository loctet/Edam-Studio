"""
Constants used in Solidity code generation.
"""

from typing import List

# Default values
DEFAULT_CALLER: str = "msg.sender"
DEFAULT_CONTRACT: str = "address(this)"
DEFAULT_STATE: str = "q0"
DEFAULT_ROLE: str = "_______R00_______"

# Operation lists
DEPLOY_OPERATIONS: List[str] = ["deploy", "start"]

UPDATE_OPERATIONS: List[str] = [
    "update_map",
    "update_list",
    "append",
    "append_list",
    "append_lists",
    "update_nested_map",
]

TRUE_VALUES: List[str] = ["True", "true"]

# Variable declarations
STATE_VARIABLE_DECLARATION: str = "State public _state;"

USERS_PERMISSIONS_DECLARATION: str = (
    "mapping(address => mapping(Roles => bool)) public _permissions;"
)

# Error messages
ROLE_CONSTRAINT_MESSAGE: str = "Role constraints not satisfied"
REENTRANT_CALL_MESSAGE: str = "Reentrant call"
CONDITION_NOT_MET_MESSAGE: str = "Condition not met"

