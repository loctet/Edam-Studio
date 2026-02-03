#!/bin/bash
# EDAM Studio Documentation Build Script
# Generates HTML documentation from Markdown using Pandoc
# Requires: Pandoc (https://pandoc.org)

set -e
DOC_DIR="$(cd "$(dirname "$0")" && pwd)"
MD_FILE="$DOC_DIR/studio-documentation.md"
CSS_FILE="$DOC_DIR/doc-style.css"
OUTPUT_FILE="$DOC_DIR/studio-documentation.html"

echo "EDAM Studio - Documentation Build"
echo "================================"

# Check Pandoc
if ! command -v pandoc &> /dev/null; then
    echo "ERROR: Pandoc is not installed or not in PATH."
    echo "Install from: https://pandoc.org/installing.html"
    exit 1
fi
echo "Using: $(pandoc --version | head -1)"

# Check source file
if [ ! -f "$MD_FILE" ]; then
    echo "ERROR: Source file not found: $MD_FILE"
    exit 1
fi

# Generate HTML
echo ""
echo "Generating HTML..."
pandoc "$MD_FILE" -o "$OUTPUT_FILE" \
    --standalone \
    --toc \
    --toc-depth=3 \
    --metadata title="EDAM Studio Documentation" \
    --metadata lang=en \
    -f markdown \
    -t html5 \
    --css=doc-style.css \
    --number-sections

echo ""
echo "SUCCESS: Documentation generated at:"
echo "  $OUTPUT_FILE"
echo ""
echo "Open in browser: file://$OUTPUT_FILE"
