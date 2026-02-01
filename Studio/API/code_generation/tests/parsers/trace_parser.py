"""Parser for test trace files."""

from typing import List, Tuple, Any

class TraceParser:
    """Parser for test trace files."""
    
    @staticmethod
    def parse_list(list_str: str) -> List[str]:
        """
        Parses a list of elements from the format [item1, item2] and returns a cleaned list.
        Handles empty lists properly.
        """
        list_str = list_str.strip()
        if list_str == "" or list_str == "[]":
            return []
        # Remove the square brackets and split on commas
        return [item.strip() for item in list_str[1:-1].split(",") if item.strip()]

    @staticmethod
    def parse_trace_line(line: str) -> Tuple[str, str, str, List[str], List[str]]:
        """
        Parses a single trace line into (edam_name, participant, operation, participants, values).
        """
        line = line.strip()
        if not line:
            raise ValueError("Empty line provided")

        # Split the line into parts using '>' and '.'
        parts = line.split(">")
        if len(parts) != 2:
            raise ValueError(f"Invalid trace format: {line}")

        participant = parts[0].strip()
        rest = parts[1].strip()

        # Split the rest into edam_name.operation and the lists
        operation_parts = rest.split(".", 1)
        if len(operation_parts) != 2:
            raise ValueError(f"Invalid trace format: {line}")

        edam_name = operation_parts[0].strip()
        operation_rest = operation_parts[1].strip()

        # Split the operation_rest into operation and the two lists
        list_parts = operation_rest.split("[", 1)
        if len(list_parts) != 2:
            raise ValueError(f"Invalid trace format: {line}")

        operation = list_parts[0].strip()
        lists_rest = "[" + list_parts[1].strip()

        # Split the lists_rest into participants and values
        lists = lists_rest.split("]", 2)
        if len(lists) != 3:
            raise ValueError(f"Invalid trace format: {line}")

        participants_str = lists[0].strip() + "]"  # Add the closing bracket back
        values_str = lists[1].strip() + "]"        # Add the closing bracket back

        # Parse participants and values
        participants = TraceParser.parse_list(participants_str)
        values = TraceParser.parse_list(values_str)

        # Convert numerical values
        processed_values = []
        for value in values:
            try:
                processed_values.append("IntVal " + str(int(value)))  # Convert to int if possible
            except ValueError:
                processed_values.append(f'StrVal "{value}"')  # Keep as string with quotes

        return edam_name, participant, operation, participants, processed_values

    @staticmethod
    def parse_multiline_trace(trace_text: str) -> List[Tuple[str, str, str, List[str], List[str]]]:
        """
        Parses a multi-line trace text and returns a list of parsed trace lines.
        """
        lines = [line.strip() for line in trace_text.strip().split("\n") if line.strip()]
        return [TraceParser.parse_trace_line(line) for line in lines]

    @staticmethod
    def format_calls(parsed_trace: List[Tuple[str, str, str, List[str], List[str]]]) -> List[str]:
        """
        Formats the parsed calls into the correct format.
        """
        calls = []
        for edam_name, participant, operation, participants, values in parsed_trace:
            # Format the parameters
            params = ", ".join(participants + [str(v) for v in values])
            # Format the participants part of the label
            participants_str = "; ".join([f'PID "{p}"' for p in participants])
            # Format the values part of the label
            values_str = "; ".join([str(v) for v in values])
            # Construct the label
            label = f'(PID "{participant}", Operation "{operation}", [{participants_str}], [{values_str}])'
            
            # Add the final output
            calls.append(f'("{edam_name}", {label}, (generate_iota_from_label "{edam_name}" {label} configurations))')
        return calls

    @staticmethod
    def get_calls_list(trace_text: str) -> List[str]:
        """
        Parses a multi-line trace text and returns a list of calls.
        """
        return TraceParser.format_calls(TraceParser.parse_multiline_trace(trace_text)) 