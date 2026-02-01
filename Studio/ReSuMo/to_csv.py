import re
import csv
import os

def extract_data(filepath):
    """Extracts mutation testing data from a text file."""

    data = {}
    with open(filepath, 'r') as f:
        content = f.read()

    # Regular expression to capture the data
    pattern = r"Results for (\w+):\n\s*----------------------------------------\n\s*Mutants Generated: (\d+)\n\s*Mutants Survived: (\d+)\n\s*Mutants Killed: (\d+)\n\s*Mutants Stillborn: (\d+)\n\s*Mutants Equivalent: (\d+)\n\s*Mutants Redundant: (\d+)\n\s*Mutants Timed Out: (\d+)\n\s*Mutation Score: ([\d.]+) %"

    matches = re.findall(pattern, content)

    for match in matches:
        operator = match[0]
        data[operator] = {
            "Mutants Generated": int(match[1]),
            "Mutants Survived": int(match[2]),
            "Mutants Killed": int(match[3]),
            "Mutants Stillborn": int(match[4]),
            "Mutants Equivalent": int(match[5]),
            "Mutants Redundant": int(match[6]),
            "Mutants Timed Out": int(match[7]),
            "Mutation Score": float(match[8])
        }
    return data

def write_to_csv(data, output_filename="mutation_results.csv"):
    """Writes the extracted data to a CSV file."""

    if not data:  # Check if data is empty
        print("No data to write to CSV.")
        return

    fieldnames = ["Operator", "Mutants Generated", "Mutants Survived", "Mutants Killed",
                  "Mutants Stillborn", "Mutants Equivalent", "Mutants Redundant",
                  "Mutants Timed Out", "Mutation Score"]

    with open(output_filename, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for operator, metrics in data.items():
            row = {"Operator": operator}
            row.update(metrics)
            writer.writerow(row)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Process mutation testing result files.")
    parser.add_argument("input_files", nargs="+", help="One or more input text files.")
    parser.add_argument("-o", "--output", help="Output CSV filename", default="mutation_results.csv")
    args = parser.parse_args()

    all_data = {}
    for input_file in args.input_files:
        if os.path.exists(input_file):
            file_data = extract_data(input_file)
            write_to_csv(file_data, f"{input_file}.csv")
            print(f"Results written to {args.output}")
        else:
            print(f"File not found: {input_file}")