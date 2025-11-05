#!/bin/bash
set -e  # Exit on error
set -o pipefail  # Pipe failures cause script to exit

# Function to display usage
show_usage() {
    echo "Usage: $0 <input_directory> <output_directory> [prefix]"
    echo ""
    echo "Arguments:"
    echo "  input_directory  - Directory containing reduced repo examples to copy"
    echo "  output_directory - Where to create the model test copies"
    echo "  prefix          - Optional prefix for output directories (default: 'test')"
    echo ""
    echo "This will create in the output directory:"
    echo "  <prefix>_sonnet-4-5_refine/"
    echo "  <prefix>_sonnet-4-5_base/"
    echo "  <prefix>_sonnet-4-5_incremental/"
    echo "  <prefix>_opus-4-1_refine/"
    echo "  <prefix>_opus-4-1_base/"
    echo "  <prefix>_opus-4-1_incremental/"
    echo ""
    echo "Example:"
    echo "  $0 ./repos_reduced /path/to/output mytest"
    echo "  Creates: mytest_sonnet-4-5_refine, mytest_sonnet-4-5_base, etc."
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    show_usage
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
PREFIX="${3:-test}"  # Default prefix is 'test' if not provided

# Remove trailing slashes for consistency
INPUT_DIR="${INPUT_DIR%/}"
OUTPUT_DIR="${OUTPUT_DIR%/}"

# Validate input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# Define the target configurations
MODELS=("sonnet-4-5" "opus-4-1")
STRATEGIES=("refine" "base" "incremental")

# Colors for output (check if terminal supports colors)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

echo -e "${BLUE}Starting copy process...${NC}"
echo "Input directory: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Prefix: $PREFIX"
echo ""

# Counter for successful copies
COPIED=0
FAILED=0
TOTAL=$((${#MODELS[@]} * ${#STRATEGIES[@]}))

# Create copies for each combination
for MODEL in "${MODELS[@]}"; do
    for STRATEGY in "${STRATEGIES[@]}"; do
        TARGET_NAME="${PREFIX}_${MODEL}_${STRATEGY}"
        TARGET_PATH="${OUTPUT_DIR}/${TARGET_NAME}"
        
        echo -n "Creating $TARGET_NAME... "
        
        # Remove target if it exists
        if [ -d "$TARGET_PATH" ]; then
            echo -n "(removing existing) "
            rm -rf "$TARGET_PATH" || {
                echo -e "${RED}Failed to remove existing directory${NC}"
                FAILED=$((FAILED + 1))
                continue
            }
        fi
        
        # Copy the entire directory recursively (including .venv for isolation)
        if cp -r "$INPUT_DIR" "$TARGET_PATH" 2>/dev/null; then
            # Try to create metadata file, but don't fail if we can't
            if [ -d "$TARGET_PATH" ]; then
                cat > "$TARGET_PATH/.test_metadata" 2>/dev/null <<EOF
model: $MODEL
strategy: $STRATEGY
source: $INPUT_DIR
created: $(date -u +"%Y-%m-%d %H:%M:%S UTC" 2>/dev/null || echo "unknown")
venv_included: yes
EOF
            fi
            
            echo -e "${GREEN}Done${NC}"
            COPIED=$((COPIED + 1))
        else
            echo -e "${RED}Failed${NC}"
            FAILED=$((FAILED + 1))
        fi
    done
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary:${NC}"
echo "Successfully created: $COPIED/$TOTAL directories"
if [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}Failed: $FAILED${NC}"
fi

# List created directories with details
if [ $COPIED -gt 0 ]; then
    echo ""
    echo "Created directories:"
    for MODEL in "${MODELS[@]}"; do
        for STRATEGY in "${STRATEGIES[@]}"; do
            TARGET_NAME="${PREFIX}_${MODEL}_${STRATEGY}"
            TARGET_PATH="${OUTPUT_DIR}/${TARGET_NAME}"
            if [ -d "$TARGET_PATH" ]; then
                # Count subdirectories/files
                if command -v find >/dev/null 2>&1; then
                    SUBDIRS=$(find "$TARGET_PATH" -maxdepth 1 -type d | wc -l)
                    SUBDIRS=$((SUBDIRS - 1))  # Subtract the directory itself
                    FILES=$(find "$TARGET_PATH" -type f | wc -l)
                    echo -e "  ${GREEN}✓${NC} $TARGET_NAME (${SUBDIRS} subdirs, ${FILES} files)"
                else
                    echo -e "  ${GREEN}✓${NC} $TARGET_NAME"
                fi
            fi
        done
    done
fi

# Show what's in the output directory
echo ""
echo "Output directory contents:"
ls -la "$OUTPUT_DIR" 2>/dev/null | grep "^d" | grep -v "^\." || echo "  (empty or error listing)"

# Exit with error if not all copies were successful
if [ $COPIED -ne $TOTAL ]; then
    echo ""
    echo -e "${RED}Warning: Not all copies completed successfully!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All $TOTAL copies completed successfully!${NC}"
exit 0