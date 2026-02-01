"""Main test generation logic."""

from typing import Dict, List, Any
from .templates.test_templates import (
    EDAM_TEMPLATE,
    CONFIGURATIONS_TEMPLATE,
    DEPENDENCIES_MAP_TEMPLATE,
    DEPENDENCY_ENTRY_TEMPLATE
)

class TestGenerator:
    """Generates test code for EDAM instances."""

    def __init__(self):
        """Initialize the test generator."""
        pass

    def generate_edam_test_code(self, edam_data: List[Dict[str, Any]]) -> str:
        """
        Generates OCaml code for multiple EDAM instances, configurations, and dependencies map.

        Args:
            edam_data (list of dict): Each dictionary contains 'edamCode' (OCaml EDAM definition) and 'name' (EDAM name).

        Returns:
            str: Complete OCaml code for all EDAM instances, configurations, and the dependencies map.
        """
        edam_code_collector = ""
        dependency_entries_collector = ""

        for edam in edam_data:
            edam_code = edam.get('edamCode')
            edam_name = edam.get('name').lower()

            #print(edam_code)
            if not edam_code or not edam_name:
                raise ValueError("Each EDAM entry must include 'edamCode' and 'name'.")
            
            # Generate EDAM-specific configuration code
            edam_specific_code = EDAM_TEMPLATE.format(edam_name=edam_name, edam_code=edam_code)
            edam_code_collector += edam_specific_code + "\n\n"

            # Generate dependency entry for this EDAM
            dependency_entry = DEPENDENCY_ENTRY_TEMPLATE.format(edam_name=edam_name)
            dependency_entries_collector += dependency_entry + "\n"
        # Generate the `configurations` structure
        configurations_code = CONFIGURATIONS_TEMPLATE.format(size=len(edam_data))

        # Generate the final dependencies_map code
        dependencies_map_code = DEPENDENCIES_MAP_TEMPLATE.format(
            size=len(edam_data),
            dependency_entries=dependency_entries_collector.strip()
        )

        # Combine all the generated code
        final_code = configurations_code + "\n" + edam_code_collector + "\n" + dependencies_map_code
        return final_code, edam_name