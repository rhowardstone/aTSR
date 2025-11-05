#!/bin/bash

# Reproducible test repository setup script
# Creates original and reduced-test versions of popular Python repos
# WITH PINNED VERSIONS FOR REPRODUCIBILITY

set -e  # Exit on error
set -o pipefail  # Pipe failures cause script to exit

# PINNED VERSIONS FOR REPRODUCIBILITY
# These are the LATEST releases as of September 30, 2025
# This captures what you'd get TODAY, but frozen for reproducibility
MISTUNE_TAG="v3.1.4"       # Latest release: Aug 29, 2025
MISTUNE_COMMIT="b6d83e82"  # Corresponds to v3.1.4 tag
SCHEDULE_TAG="1.2.2"        # Latest release: Oct 22, 2023 (still current)
SCHEDULE_COMMIT="073dbc6"   # Corresponds to 1.2.2 tag
CLICK_TAG="8.3.0"           # Latest release: Sep 18, 2025
CLICK_COMMIT="00fadb8"     # Corresponds to 8.3.0 tag

# Check if output directory argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <output_directory>"
    echo "Example: $0 /path/to/output"
    echo ""
    echo "This will create:"
    echo "  <output_directory>/repos/        - Original repositories"
    echo "  <output_directory>/repos_reduced/ - Reduced test versions"
    echo ""
    echo "Using pinned versions for reproducibility (latest as of Sep 30, 2025):"
    echo "  - mistune: $MISTUNE_TAG (commit: $MISTUNE_COMMIT)"
    echo "  - schedule: $SCHEDULE_TAG (commit: $SCHEDULE_COMMIT)" 
    echo "  - click: $CLICK_TAG (commit: $CLICK_COMMIT)"
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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Test Repository Setup Script ===${NC}"
echo -e "${BLUE}Using reproducible pinned versions (latest as of Sep 30, 2025):${NC}"
echo "  mistune: $MISTUNE_TAG (Aug 29, 2025)"
echo "  schedule: $SCHEDULE_TAG (Oct 22, 2023 - still latest)"
echo "  click: $CLICK_TAG (Sep 18, 2025)"
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

# NOTE: Dependencies will be installed in per-repo venvs (see below)
echo -e "${YELLOW}Test dependencies will be installed in isolated venvs for each repo${NC}"

# Function to clone and checkout specific version
clone_and_checkout() {
    local repo_url=$1
    local repo_name=$2
    local tag=$3
    local commit=$4

    echo -e "${BLUE}Cloning $repo_name and checking out $tag...${NC}"
    git clone "$repo_url" --quiet
    cd "$repo_name"

    # Try to checkout by tag first, fall back to commit if tag doesn't exist
    if git rev-parse "$tag" >/dev/null 2>&1; then
        git checkout "$tag" --quiet 2>/dev/null
        echo "  Checked out tag: $tag"
    else
        git checkout "$commit" --quiet 2>/dev/null
        echo "  Checked out commit: $commit"
    fi

    # Verify we're at the expected commit
    local current_commit=$(git rev-parse --short HEAD)
    echo "  Current commit: $current_commit"

    cd ..
}

# Function to create and setup virtual environment
setup_venv() {
    local repo_path=$1
    local repo_name=$2

    echo -e "${YELLOW}Creating isolated virtual environment for $repo_name...${NC}"
    cd "$repo_path"

    # Create venv
    python3 -m venv .venv

    # Activate venv
    source .venv/bin/activate

    # Upgrade pip to avoid warnings
    pip install --upgrade pip -q 2>/dev/null

    # Install testing dependencies
    echo "  Installing pytest, pytest-cov, coverage..."
    pip install -q pytest pytest-cov coverage 2>/dev/null || {
        echo -e "${YELLOW}  Warning: Some packages may have failed to install${NC}"
    }

    # Try to install the package itself
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        echo "  Installing $repo_name package..."
        pip install -e . -q 2>/dev/null || {
            pip install -r requirements.txt -q 2>/dev/null || {
                echo -e "${YELLOW}  Warning: Failed to install $repo_name dependencies${NC}"
            }
        }
    fi

    echo -e "  ${GREEN}✓ Virtual environment ready at $repo_path/.venv${NC}"

    # Deactivate for now (will be reactivated when needed)
    deactivate

    cd "$OUTPUT_DIR"
}

# Function to analyze repository
analyze_repo() {
    local repo_name=$1
    local repo_path=$2
    local module_name=$3  # Optional module name for coverage

    echo -e "${GREEN}Analyzing $repo_name...${NC}"
    cd "$repo_path"

    # Activate venv if it exists
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        echo "  Using isolated venv"
    else
        echo -e "${YELLOW}  Warning: No venv found, using system Python${NC}"
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

    # Deactivate venv
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi

    cd "$OUTPUT_DIR"
}

# Function to create reduced test version (unchanged from original)
create_reduced_version() {
    local repo_name=$1
    local source_path=$2
    local target_path=$3
    local module_name=$4  # Optional module name

    echo -e "${GREEN}Creating reduced test version of $repo_name...${NC}"

    # Copy entire repository
    cp -r "$source_path" "$target_path"
    cd "$target_path"

    # Remove git history to prevent seeing deleted files
    echo "  Removing git history..."
    rm -rf .git

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

    # Run coverage on reduced version
    echo "Analyzing reduced coverage..."

    # Activate venv if it exists
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        echo "  Using isolated venv"
    fi

    python -m pytest $test_target --cov="$module_name" --cov-report=term --tb=no -q 2>&1 | tee "$OUTPUT_DIR/${repo_name}_coverage_reduced.txt" || {
        echo -e "${YELLOW}Reduced coverage analysis completed${NC}"
    }

    # Deactivate venv
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi

    cd "$OUTPUT_DIR"
}

echo ""
echo -e "${GREEN}=== Repository 1: mistune (Markdown parser) ===${NC}"
echo "Size: ~2600 LOC, Testing: pytest"
echo "Version: $MISTUNE_TAG (Latest release)"
cd "$REPOS_DIR"
clone_and_checkout "https://github.com/lepture/mistune.git" "mistune" "$MISTUNE_TAG" "$MISTUNE_COMMIT"
setup_venv "$REPOS_DIR/mistune" "mistune"
analyze_repo "mistune" "$REPOS_DIR/mistune" "mistune"
create_reduced_version "mistune" "$REPOS_DIR/mistune" "$REDUCED_DIR/mistune" "mistune"
setup_venv "$REDUCED_DIR/mistune" "mistune"

echo ""
echo -e "${GREEN}=== Repository 2: schedule (Job scheduling) ===${NC}"
echo "Size: ~400 LOC, Testing: pytest"
echo "Version: $SCHEDULE_TAG (Latest release)"
cd "$REPOS_DIR"
clone_and_checkout "https://github.com/dbader/schedule.git" "schedule" "$SCHEDULE_TAG" "$SCHEDULE_COMMIT"
setup_venv "$REPOS_DIR/schedule" "schedule"
analyze_repo "schedule" "$REPOS_DIR/schedule" "schedule"
create_reduced_version "schedule" "$REPOS_DIR/schedule" "$REDUCED_DIR/schedule" "schedule"
setup_venv "$REDUCED_DIR/schedule" "schedule"

echo ""
echo -e "${GREEN}=== Repository 3: click (CLI framework) ===${NC}"
echo "Size: ~8000 LOC, Testing: pytest"
echo "Version: $CLICK_TAG (Latest release)"
cd "$REPOS_DIR"
clone_and_checkout "https://github.com/pallets/click.git" "click" "$CLICK_TAG" "$CLICK_COMMIT"
setup_venv "$REPOS_DIR/click" "click"
analyze_repo "click" "$REPOS_DIR/click" "click"
create_reduced_version "click" "$REPOS_DIR/click" "$REDUCED_DIR/click" "click"
setup_venv "$REDUCED_DIR/click" "click"

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo -e "${BLUE}Reproducible versions used (latest as of Sep 30, 2025):${NC}"
echo "  mistune: $MISTUNE_TAG (commit: $MISTUNE_COMMIT)"
echo "  schedule: $SCHEDULE_TAG (commit: $SCHEDULE_COMMIT)"
echo "  click: $CLICK_TAG (commit: $CLICK_COMMIT)"
echo ""
echo -e "${BLUE}Environment isolation:${NC}"
echo "  Each repository has an isolated virtual environment at .venv/"
echo "  This ensures no dependency conflicts between repos or runs"
echo ""
echo "Repository structure:"
echo "  Original repos: $REPOS_DIR/ (with .venv/)"
echo "  Reduced test repos: $REDUCED_DIR/ (with .venv/)"
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
echo "3. Execute: /refine-tests auto"
echo ""
echo "Note: These versions are the latest releases as of Sep 30, 2025,"
echo "      frozen for reproducibility. Anyone running this script will"
echo "      get exactly these versions."