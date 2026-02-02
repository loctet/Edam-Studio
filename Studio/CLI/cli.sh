#!/bin/bash
#
# Edam Studio CLI Wrapper
# Supports:
#   .generate edams <models> [options] -> calls cli.py
#   .run resumo <zip_file> -> runs ReSuMo on a specific zip file
#   .run test <zip_file> [command] -> runs test/coverage on a zip file
#   .run experiment_data [--mutation <zip_file>] -> processes all zips in EXPERIMENT_DATA
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI_COMMANDS="$SCRIPT_DIR/cli_commands.py"

# Function to show usage
usage() {
    echo "Usage:"
    echo "  .generate edams <model1> <model2> ... --mode <1|2|3|4> [options]"
    echo "  .run resumo <zip_file>"
    echo "  .run test <zip_file> [test|coverage|custom_command]"
    echo "  .run experiment_data [--mutation <zip_file>]"
    echo ""
    echo "Examples:"
    echo "  .generate edams Model1 Model2 --mode 1"
    echo "  .run resumo myfile.zip"
    echo "  .run test myfile.zip test"
    echo "  .run test myfile.zip coverage"
    echo "  .run experiment_data"
    echo "  .run experiment_data --mutation myfile.zip"
    exit 1
}

# Check if Python script exists
if [ ! -f "$CLI_COMMANDS" ]; then
    echo "Error: cli_commands.py not found at $CLI_COMMANDS"
    exit 1
fi

# Parse command
if [ "$1" = ".generate" ]; then
    shift
    if [ "$1" = "edams" ]; then
        shift
        python3 "$CLI_COMMANDS" generate edams "$@"
    else
        echo "Error: Unknown generate action. Use 'edams'"
        usage
    fi
elif [ "$1" = ".run" ]; then
    shift
    if [ "$1" = "resumo" ]; then
        shift
        if [ -z "$1" ]; then
            echo "Error: ZIP file name required"
            usage
        fi
        python3 "$CLI_COMMANDS" run resumo "$1"
    elif [ "$1" = "test" ]; then
        shift
        if [ -z "$1" ]; then
            echo "Error: ZIP file name required"
            usage
        fi
        ZIP_FILE="$1"
        shift
        COMMAND="${1:-test}"
        python3 "$CLI_COMMANDS" run test "$ZIP_FILE" "$COMMAND"
    elif [ "$1" = "experiment_data" ]; then
        shift
        if [ "$1" = "--mutation" ]; then
            shift
            if [ -z "$1" ]; then
                echo "Error: ZIP file name required for mutation"
                usage
            fi
            python3 "$CLI_COMMANDS" run experiment_data --mutation "$1"
        else
            python3 "$CLI_COMMANDS" run experiment_data
        fi
    else
        echo "Error: Unknown run action. Use 'resumo', 'test', or 'experiment_data'"
        usage
    fi
else
    echo "Error: Unknown command. Use '.generate' or '.run'"
    usage
fi
