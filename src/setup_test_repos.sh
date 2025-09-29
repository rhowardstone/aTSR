#!/bin/bash

# Reproducible test repository setup script
# Creates original and reduced-test versions of popular Python repos

set -e  # Exit on error
set -o pipefail  # Pipe failures cause script to exit

# Check if output directory argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <output_directory>"
    echo "Example: $0 /path/to/output"
    echo ""
    echo "This will create:"
    echo "  <output_directory>/repos/        - Original repositories"
    echo "  <output_directory>/repos_reduced/ - Reduced test versions"
    exit 1
fi

OUTPUT_DIR="$1"

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# Convert to absolute path
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
REPOS_DIR="$OUTPUT_DIR/repos"
REDUCED_DIR="$OUTPUT_DIR/repos_reduced"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Test Repository Setup Script ===${NC}"
echo "This script will clone 3 popular Python repos and create test-reduced versions"
echo ""

# Clean up any existing directories
if [ -d "$REPOS_DIR" ] || [ -d "$REDUCED_DIR" ]; then
    echo -e "${YELLOW}Cleaning up existing directories...${NC}"
    rm -rf "$REPOS_DIR" "$REDUCED_DIR"
fi

mkdir -p "$REPOS_DIR"
mkdir -p "$REDUCED_DIR"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check requirements
echo -e "${YELLOW}Checking requirements...${NC}"
if ! command_exists python3; then
    echo -e "${RED}Error: Python 3 is required${NC}"
    exit 1
fi

if ! command_exists git; then
    echo -e "${RED}Error: git is required${NC}"
    exit 1
fi

# Install testing dependencies
echo -e "${YELLOW}Installing test dependencies...${NC}"
pip install -q pytest pytest-cov coverage 2>/dev/null || {
    echo -e "${RED}Warning: Some packages may already be installed${NC}"
}

# Function to analyze repository
analyze_repo() {
    local repo_name=$1
    local repo_path=$2
    local module_name=$3  # Optional module name for coverage

    echo -e "${GREEN}Analyzing $repo_name...${NC}"
    cd "$repo_path"

    # Try to install the package
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        echo "Installing package..."
        pip install -e . -q 2>/dev/null || {
            pip install -r requirements.txt -q 2>/dev/null || {
                echo -e "${YELLOW}Warning: Failed to install $repo_name dependencies${NC}"
            }
        }

    fi

    # Find test directory/files
    local test_target=""
    if [ -d "tests" ]; then
        test_target="tests"
    elif [ -d "test" ]; then
        test_target="test"
    elif [ -f "test_${repo_name}.py" ]; then
        test_target="test_${repo_name}.py"
    elif ls test_*.py 2>/dev/null | head -1; then
        test_target="test_*.py"
    else
        echo -e "${YELLOW}No tests found for $repo_name${NC}"
        return
    fi

    # Determine module name for coverage
    if [ -z "$module_name" ]; then
        if [ -d "$repo_name" ]; then
            module_name="$repo_name"
        elif [ -d "src/$repo_name" ]; then
            module_name="src.$repo_name"
        elif [ -f "${repo_name}.py" ]; then
            module_name="${repo_name}"
        else
            module_name="."
        fi
    fi

    # Run coverage analysis
    echo "Running coverage on $test_target for module $module_name..."
    python -m pytest $test_target --cov="$module_name" --cov-report=term --tb=no -q 2>&1 | tee "$OUTPUT_DIR/${repo_name}_coverage_full.txt" || {
        echo -e "${YELLOW}Coverage analysis completed with warnings for $repo_name${NC}"
    }

    cd "$OUTPUT_DIR"
}

# Function to create reduced test version
create_reduced_version() {
    local repo_name=$1
    local source_path=$2
    local target_path=$3
    local module_name=$4  # Optional module name

    echo -e "${GREEN}Creating reduced test version of $repo_name...${NC}"

    # Copy entire repository
    cp -r "$source_path" "$target_path"
    cd "$target_path"

    # Remove git directory to start fresh (no history of deleted files)
    rm -rf .git
    # Reinitialize as a new repo so git status is clean
    git init --quiet
    git config user.name "Test Setup Script" 2>/dev/null
    git config user.email "test@example.com" 2>/dev/null
    git add . >/dev/null 2>&1
    git commit -m "Initial commit with full test suite" --quiet

    # Clean function to remove test references
    clean_test_references() {
        local removed_file=$1
        local base_name=$(basename "$removed_file" .py)

        # Remove from __init__.py files
        find . -name "__init__.py" -exec sed -i "/${base_name}/d" {} \; 2>/dev/null

        # Remove from setup.py or setup.cfg
        [ -f "setup.py" ] && sed -i "/${base_name}/d" setup.py 2>/dev/null
        [ -f "setup.cfg" ] && sed -i "/${base_name}/d" setup.cfg 2>/dev/null

        # Remove from tox.ini, pytest.ini, pyproject.toml
        [ -f "tox.ini" ] && sed -i "/${base_name}/d" tox.ini 2>/dev/null
        [ -f "pytest.ini" ] && sed -i "/${base_name}/d" pytest.ini 2>/dev/null
        [ -f "pyproject.toml" ] && sed -i "/${base_name}/d" pyproject.toml 2>/dev/null

        # Remove from any test collection files
        find . -name "test_*.py" -exec sed -i "/from.*${base_name}/d; /import.*${base_name}/d" {} \; 2>/dev/null
    }

    # Strategy depends on repository structure
    case "$repo_name" in
        mistune)
            # Remove specific test files to get ~48-50% coverage
            for test_file in tests/test_directives.py tests/test_plugins.py tests/test_misc.py tests/test_hooks.py tests/test_renderers.py; do
                if [ -f "$test_file" ]; then
                    echo "  Removing: $test_file"
                    rm -f "$test_file"
                    clean_test_references "$test_file"
                fi
            done
            ;;
        schedule)
            # For schedule, aggressively reduce to get ~50% coverage
            if [ -f "test_schedule.py" ]; then
                # Keep only first 3 tests to get lower coverage
                python3 -c "
import re
with open('test_schedule.py', 'r') as f:
    content = f.read()

# Split into parts before test functions
parts = content.split('def test_')
# Keep header and only first 3 test functions
keep = parts[0]  # Header with imports and setup
for i in range(1, min(4, len(parts))):  # Keep only 3 tests
    keep += 'def test_' + parts[i]

with open('test_schedule.py', 'w') as f:
    f.write(keep)
" 2>/dev/null || echo "Could not reduce schedule tests"
                echo "Reduced test_schedule.py to ~3 tests for lower coverage"
            fi
            ;;
        click)
            # Remove 14 of 20 test files for ~50% coverage (from 80%)
            # Keep only: test_arguments, test_basic, test_context, test_defaults, test_imports, test_info_dict
            for test_file in tests/test_commands.py tests/test_options.py tests/test_chain.py tests/test_utils.py tests/test_types.py tests/test_parser.py tests/test_compat.py tests/test_custom_classes.py tests/test_normalization.py tests/test_shell_completion.py tests/test_formatting.py tests/test_termui.py tests/test_testing.py tests/test_command_decorators.py; do
                if [ -f "$test_file" ]; then
                    echo "  Removing: $test_file"
                    rm -f "$test_file"
                    clean_test_references "$test_file"
                fi
            done
            ;;
        *)
            # Generic approach: remove every other test file
            local test_files=()
            if [ -d "tests" ]; then
                mapfile -t test_files < <(find tests -name "test_*.py" -type f 2>/dev/null | sort)
            elif [ -d "test" ]; then
                mapfile -t test_files < <(find test -name "test_*.py" -type f 2>/dev/null | sort)
            else
                mapfile -t test_files < <(find . -maxdepth 2 -name "test_*.py" -type f 2>/dev/null | sort)
            fi

            local num_files=${#test_files[@]}
            if [ $num_files -gt 0 ]; then
                echo "Found $num_files test files, removing half..."
                for ((i=1; i<${#test_files[@]}; i+=2)); do
                    echo "  Removing: ${test_files[$i]}"
                    rm -f "${test_files[$i]}"
                    clean_test_references "${test_files[$i]}"
                done
            fi
            ;;
    esac

    # Determine test target and module
    local test_target=""
    if [ -d "tests" ]; then
        test_target="tests"
    elif [ -d "test" ]; then
        test_target="test"
    elif [ -f "test_${repo_name}.py" ]; then
        test_target="test_${repo_name}.py"
    else
        test_target="."
    fi

    if [ -z "$module_name" ]; then
        if [ -d "$repo_name" ]; then
            module_name="$repo_name"
        elif [ -d "src/$repo_name" ]; then
            module_name="src.$repo_name"
        else
            module_name="."
        fi
    fi

    # Commit the changes after removing tests so git status is clean
    git add -A >/dev/null 2>&1
    git commit -m "Reduced test suite to ~50% coverage" --quiet 2>/dev/null || {
        echo "No changes to commit (no tests removed)"
    }

    # Run coverage on reduced version
    echo "Analyzing reduced coverage..."
    python -m pytest $test_target --cov="$module_name" --cov-report=term --tb=no -q 2>&1 | tee "$OUTPUT_DIR/${repo_name}_coverage_reduced.txt" || {
        echo -e "${YELLOW}Reduced coverage analysis completed${NC}"
    }

    cd "$OUTPUT_DIR"
}

echo ""
echo -e "${GREEN}=== Repository 1: mistune (Markdown parser) ===${NC}"
echo "Size: ~2600 LOC, Testing: pytest"
cd "$REPOS_DIR"
git clone https://github.com/lepture/mistune.git --quiet
analyze_repo "mistune" "$REPOS_DIR/mistune" "mistune"
create_reduced_version "mistune" "$REPOS_DIR/mistune" "$REDUCED_DIR/mistune" "mistune"

echo ""
echo -e "${GREEN}=== Repository 2: schedule (Job scheduling) ===${NC}"
echo "Size: ~400 LOC, Testing: pytest"
cd "$REPOS_DIR"
git clone https://github.com/dbader/schedule.git --quiet
analyze_repo "schedule" "$REPOS_DIR/schedule" "schedule"
create_reduced_version "schedule" "$REPOS_DIR/schedule" "$REDUCED_DIR/schedule" "schedule"

echo ""
echo -e "${GREEN}=== Repository 3: click (CLI framework) ===${NC}"
echo "Size: ~8000 LOC, Testing: pytest"
cd "$REPOS_DIR"
git clone https://github.com/pallets/click.git --quiet
analyze_repo "click" "$REPOS_DIR/click" "click"
create_reduced_version "click" "$REPOS_DIR/click" "$REDUCED_DIR/click" "click"


echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Repository structure:"
echo "  Original repos: $REPOS_DIR/"
echo "  Reduced test repos: $REDUCED_DIR/"
echo ""
echo "Coverage reports saved:"
ls -la "$OUTPUT_DIR"/*_coverage_*.txt 2>/dev/null || echo "  No coverage reports generated"

echo ""
echo -e "${GREEN}Summary:${NC}"
for repo in mistune schedule click; do
    echo ""
    echo "$repo:"
    if [ -f "$OUTPUT_DIR/${repo}_coverage_full.txt" ]; then
        echo -n "  Full coverage: "
        grep "TOTAL" "$OUTPUT_DIR/${repo}_coverage_full.txt" 2>/dev/null | awk '{print $NF}' || echo "N/A"
    fi
    if [ -f "$OUTPUT_DIR/${repo}_coverage_reduced.txt" ]; then
        echo -n "  Reduced coverage: "
        grep "TOTAL" "$OUTPUT_DIR/${repo}_coverage_reduced.txt" 2>/dev/null | awk '{print $NF}' || echo "N/A"
    fi
done

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. cd $REDUCED_DIR/<repo_name>"
echo "2. Run: claude"
echo "3. Execute: /refine-tests-v2 auto"
echo ""
