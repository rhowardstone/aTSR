#!/bin/bash
# Evaluate test metrics for improved test suites
# Measures coverage, test count, pass rate, and compares to baseline
# FIXED VERSION - handles problematic test files better

#set -e
#set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Usage function
show_usage() {
    echo "Usage: $0 <test_dir> <repo_type> [--baseline <baseline_dir>] [--output <output_file>]"
    echo ""
    echo "Arguments:"
    echo "  test_dir     - Directory containing the improved test suite"
    echo "  repo_type    - One of: schedule, mistune, click"
    echo ""
    echo "Options:"
    echo "  --baseline DIR   - Original directory to compare against"
    echo "  --output FILE    - Output JSON file for metrics (default: metrics.json)"
    echo "  --verbose        - Show detailed output"
    echo ""
    echo "Example:"
    echo "  $0 ./improved/schedule schedule --baseline ./original/schedule"
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    show_usage
fi

TEST_DIR="$1"
REPO_TYPE="$2"
shift 2

# Parse optional arguments
BASELINE_DIR=""
OUTPUT_FILE="metrics.json"
VERBOSE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --baseline)
            BASELINE_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Check for required tools
if ! command -v bc &> /dev/null; then
    echo -e "${YELLOW}Warning: 'bc' calculator not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y bc 2>/dev/null || echo "Could not install bc, percentages may not work"
    elif command -v yum &> /dev/null; then
        sudo yum install -y bc 2>/dev/null || echo "Could not install bc, percentages may not work"
    else
        echo "Please install 'bc' for percentage calculations"
    fi
fi

# Validate inputs
if [ ! -d "$TEST_DIR" ]; then
    echo -e "${RED}Error: Directory '$TEST_DIR' does not exist${NC}"
    exit 1
fi

if [[ ! "$REPO_TYPE" =~ ^(schedule|mistune|click)$ ]]; then
    echo -e "${RED}Error: Invalid repo type '$REPO_TYPE'${NC}"
    echo "Must be one of: schedule, mistune, click"
    exit 1
fi

# Store original directory for output file
ORIGINAL_DIR="$(pwd)"

# Convert OUTPUT_FILE to absolute path if it's not already
if [[ "$OUTPUT_FILE" != /* ]]; then
    OUTPUT_FILE="$ORIGINAL_DIR/$OUTPUT_FILE"
fi

# Convert directories to absolute paths
TEST_DIR="$(cd "$TEST_DIR" && pwd)"
if [ -n "$BASELINE_DIR" ]; then
    BASELINE_DIR="$(cd "$BASELINE_DIR" && pwd)"
fi

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}    Test Metrics Evaluation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo "Repository: $REPO_TYPE"
echo "Test directory: $TEST_DIR"
if [ -n "$BASELINE_DIR" ]; then
    echo "Baseline directory: $BASELINE_DIR"
fi
echo "Output file: $OUTPUT_FILE"
echo ""

# Change to test directory
cd "$TEST_DIR"

# Function to count test functions (improved to catch all patterns)
count_test_functions() {
    local DIR="$1"
    local COUNT=0
    
    case "$REPO_TYPE" in
        schedule)
            # Count all test files
            for file in "$DIR"/test*.py "$DIR"/*test*.py; do
                if [ -f "$file" ]; then
                    local file_count=$(grep -c "^def test_\|^    def test_\|^        def test_" "$file" 2>/dev/null || echo 0)
                    file_count=$(echo "$file_count" | tr -d '\n\r ')
                    COUNT=$((COUNT + file_count))
                fi
            done
            ;;
        mistune|click)
            # Multiple test files in tests/ directory
            if [ -d "$DIR/tests" ]; then
                for file in "$DIR/tests"/test*.py "$DIR/tests"/*test*.py; do
                    if [ -f "$file" ]; then
                        local file_count=$(grep -c "^def test_\|^    def test_\|^        def test_" "$file" 2>/dev/null || echo 0)
                        file_count=$(echo "$file_count" | tr -d '\n\r ')
                        COUNT=$((COUNT + file_count))
                    fi
                done
            fi
            ;;
    esac
    
    echo "$COUNT"
}

# Function to count lines of test code
count_test_lines() {
    local DIR="$1"
    local COUNT=0
    
    case "$REPO_TYPE" in
        schedule)
            # Count all test files
            for file in "$DIR"/test*.py "$DIR"/*test*.py; do
                if [ -f "$file" ]; then
                    local file_lines=$(wc -l < "$file" 2>/dev/null || echo 0)
                    file_lines=$(echo "$file_lines" | tr -d '\n\r ')
                    COUNT=$((COUNT + file_lines))
                fi
            done
            ;;
        mistune|click)
            if [ -d "$DIR/tests" ]; then
                local total_lines=$(find "$DIR/tests" -name "test*.py" -o -name "*test*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
                total_lines=$(echo "$total_lines" | tr -d '\n\r ')
                if [ -n "$total_lines" ] && [ "$total_lines" != "" ]; then
                    COUNT=$total_lines
                fi
            fi
            ;;
    esac
    
    echo "$COUNT"
}

# Initialize metrics
METRICS="{}"

# Count test functions and lines
echo -e "${CYAN}Counting tests...${NC}"
TEST_FUNCTIONS=$(count_test_functions "$TEST_DIR")
TEST_LINES=$(count_test_lines "$TEST_DIR")

echo "  Test functions: $TEST_FUNCTIONS"
echo "  Test lines: $TEST_LINES"

# If baseline provided, calculate differences
FUNCTIONS_ADDED=0
LINES_ADDED=0
FUNCTION_INCREASE=0

if [ -n "$BASELINE_DIR" ]; then
    echo ""
    echo -e "${CYAN}Comparing to baseline...${NC}"
    BASELINE_FUNCTIONS=$(count_test_functions "$BASELINE_DIR")
    BASELINE_LINES=$(count_test_lines "$BASELINE_DIR")
    
    FUNCTIONS_ADDED=$((TEST_FUNCTIONS - BASELINE_FUNCTIONS))
    LINES_ADDED=$((TEST_LINES - BASELINE_LINES))
    
    echo "  Baseline functions: $BASELINE_FUNCTIONS"
    echo "  Baseline lines: $BASELINE_LINES"
    echo -e "${GREEN}  Functions added: +$FUNCTIONS_ADDED${NC}"
    echo -e "${GREEN}  Lines added: +$LINES_ADDED${NC}"
    
    # Calculate percentage increase
    if [ $BASELINE_FUNCTIONS -gt 0 ]; then
        FUNCTION_INCREASE=$(echo "scale=1; ($FUNCTIONS_ADDED * 100) / $BASELINE_FUNCTIONS" | bc)
        echo "  Function increase: ${FUNCTION_INCREASE}%"
    else
        FUNCTION_INCREASE=0
    fi
fi

# Run tests and measure pass rate - FIXED VERSION
echo ""
echo -e "${CYAN}Running tests...${NC}"

# Prepare test command based on repo type - use verbose output instead of quiet
case "$REPO_TYPE" in
    schedule)
        # Use verbose output to get parseable results
        TEST_CMD="timeout 60 python -m pytest test*.py --tb=short -v --timeout=10 --timeout-method=thread 2>&1"
        ;;
    mistune)
        TEST_CMD="timeout 60 python -m pytest tests/ --tb=short -v --timeout=10 --timeout-method=thread 2>&1"
        ;;
    click)
        TEST_CMD="timeout 60 python -m pytest tests/ --tb=short -v --timeout=10 --timeout-method=thread 2>&1"
        ;;
esac

# Install pytest-timeout if needed
if ! python -c "import pytest_timeout" 2>/dev/null; then
    echo "  Installing pytest-timeout for safer test execution..."
    pip install pytest-timeout -q 2>/dev/null || true
fi

# Run tests and capture results
TEST_OUTPUT=$(mktemp)
TESTS_PASSED=0
TESTS_FAILED=0

# Use eval to properly handle the timeout and pipes
if eval $TEST_CMD > "$TEST_OUTPUT"; then
    TEST_RESULT="PASS"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo -e "${YELLOW}  Warning: Tests timed out${NC}"
    fi
    TEST_RESULT="PARTIAL"
fi

# Parse test results - try multiple patterns
# Pattern 1: Look for the pytest summary line "====== X passed, Y failed in Z ======"
SUMMARY_LINE=$(grep -E "=+ .*(passed|failed|error|skipped).*=+" "$TEST_OUTPUT" 2>/dev/null | tail -1)
if [ -n "$SUMMARY_LINE" ]; then
    # Extract passed count
    if echo "$SUMMARY_LINE" | grep -q "passed"; then
        TESTS_PASSED=$(echo "$SUMMARY_LINE" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1 || echo 0)
    fi
    # Extract failed count
    if echo "$SUMMARY_LINE" | grep -q "failed"; then
        TESTS_FAILED=$(echo "$SUMMARY_LINE" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo 0)
    fi
fi

# Pattern 2: If no summary line, count individual test results from verbose output
if [ "$TESTS_PASSED" = "0" ] && [ "$TESTS_FAILED" = "0" ]; then
    # Count PASSED and FAILED markers in verbose output
    local_passed=$(grep -c " PASSED" "$TEST_OUTPUT" 2>/dev/null || echo 0)
    local_failed=$(grep -c " FAILED" "$TEST_OUTPUT" 2>/dev/null || echo 0)
    
    if [ "$local_passed" -gt 0 ] || [ "$local_failed" -gt 0 ]; then
        TESTS_PASSED=$local_passed
        TESTS_FAILED=$local_failed
    fi
fi

# Pattern 3: Try collecting test results (pytest's collected X items line)
if [ "$TESTS_PASSED" = "0" ] && [ "$TESTS_FAILED" = "0" ]; then
    COLLECTED=$(grep -E "collected [0-9]+ item" "$TEST_OUTPUT" 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo 0)
    if [ "$COLLECTED" -gt 0 ]; then
        # If we collected tests but have no results, assume they all passed if exit code was 0
        if [ "$TEST_RESULT" = "PASS" ]; then
            TESTS_PASSED=$COLLECTED
            TESTS_FAILED=0
        else
            # Try to extract actual numbers from error summary
            TESTS_FAILED=$(grep -c "FAILED" "$TEST_OUTPUT" 2>/dev/null || echo 1)
            TESTS_PASSED=$((COLLECTED - TESTS_FAILED))
        fi
    fi
fi

# Ensure we have valid numbers
TESTS_PASSED=${TESTS_PASSED:-0}
TESTS_FAILED=${TESTS_FAILED:-0}

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$(echo "scale=1; ($TESTS_PASSED * 100) / $TOTAL_TESTS" | bc)
else
    PASS_RATE=0
fi

echo "  Tests passed: $TESTS_PASSED/$TOTAL_TESTS"
echo "  Pass rate: ${PASS_RATE}%"

if [ "$VERBOSE" = true ]; then
    echo ""
    echo "Test output:"
    head -50 "$TEST_OUTPUT"  # Only show first 50 lines to avoid spam
fi
rm -f "$TEST_OUTPUT"

# Measure coverage (improved version with timeout)
echo ""
echo -e "${CYAN}Measuring coverage...${NC}"

# Install coverage if needed
if ! command -v coverage &> /dev/null; then
    echo "Installing coverage tool..."
    pip install coverage pytest-cov -q
fi

# Special handling for different repos
COVERAGE_PCT=0
BRANCH_PCT=0

case "$REPO_TYPE" in
    schedule)
        # Schedule is a package with code in schedule/__init__.py
        echo "  Running coverage for schedule package..."
        
        # Check if schedule package exists
        if [ -d "schedule" ] && [ -f "schedule/__init__.py" ]; then
            # Run with timeout and safer flags - remove -q to help with parsing
            timeout 60 coverage run --source=schedule -m pytest test*.py --tb=no --timeout=10 --timeout-method=thread > /dev/null 2>&1 || true
            
            COVERAGE_OUTPUT=$(mktemp)
            coverage report > "$COVERAGE_OUTPUT" 2>&1
            
            # Look for coverage results
            COVERAGE_PCT=$(grep -E "TOTAL" "$COVERAGE_OUTPUT" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
            
            rm -f "$COVERAGE_OUTPUT"
        else
            echo -e "${YELLOW}  Warning: schedule package not found${NC}"
        fi
        ;;
        
    mistune)
        # Mistune might have src structure
        if [ -d "src/mistune" ]; then
            echo "  Running coverage for mistune module (src structure)..."
            timeout 60 bash -c "PYTHONPATH=src:$PYTHONPATH coverage run --source=src/mistune -m pytest tests/ --tb=no --timeout=10 --timeout-method=thread" > /dev/null 2>&1 || true
        elif [ -d "mistune" ]; then
            echo "  Running coverage for mistune module..."
            timeout 60 coverage run --source=mistune -m pytest tests/ --tb=no --timeout=10 --timeout-method=thread > /dev/null 2>&1 || true
        else
            echo "  Running coverage with auto-discovery..."
            timeout 60 coverage run -m pytest tests/ --tb=no --timeout=10 --timeout-method=thread > /dev/null 2>&1 || true
        fi
        
        COVERAGE_OUTPUT=$(mktemp)
        coverage report > "$COVERAGE_OUTPUT" 2>&1
        COVERAGE_PCT=$(grep "TOTAL" "$COVERAGE_OUTPUT" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
        rm -f "$COVERAGE_OUTPUT"
        ;;
        
    click)
        # Click is the most complex - try multiple approaches
        echo "  Attempting coverage measurement for click..."
        
        # Try with pytest-cov directly (often works better)
        COVERAGE_OUTPUT=$(mktemp)
        timeout 60 python -m pytest tests/ --cov=click --cov-report=term --tb=no --timeout=10 --timeout-method=thread > "$COVERAGE_OUTPUT" 2>&1 || true
        
        COVERAGE_PCT=$(grep "TOTAL" "$COVERAGE_OUTPUT" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
        
        # Try with src structure if needed
        if [ "$COVERAGE_PCT" = "0" ] || [ -z "$COVERAGE_PCT" ]; then
            if [ -d "src/click" ]; then
                timeout 60 bash -c "PYTHONPATH=src:$PYTHONPATH python -m pytest tests/ --cov=src/click --cov-report=term --tb=no --timeout=10 --timeout-method=thread" > "$COVERAGE_OUTPUT" 2>&1 || true
                COVERAGE_PCT=$(grep "TOTAL" "$COVERAGE_OUTPUT" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
            fi
        fi
        
        # Last resort note
        if [ "$COVERAGE_PCT" = "0" ] || [ -z "$COVERAGE_PCT" ]; then
            echo -e "${YELLOW}  Note: Could not measure coverage for click (complex package structure)${NC}"
        fi
        
        rm -f "$COVERAGE_OUTPUT"
        ;;
esac

# Ensure we have valid numbers
COVERAGE_PCT=${COVERAGE_PCT:-0}
BRANCH_PCT=${BRANCH_PCT:-0}

echo "  Line coverage: ${COVERAGE_PCT}%"
if [ "$BRANCH_PCT" != "0" ] && [ "$BRANCH_PCT" != "$COVERAGE_PCT" ]; then
    echo "  Branch coverage: ${BRANCH_PCT}%"
fi

# Baseline coverage comparison
BASELINE_COVERAGE=0
COVERAGE_INCREASE=0

if [ -n "$BASELINE_DIR" ]; then
    echo ""
    echo -e "${CYAN}Measuring baseline coverage...${NC}"
    
    # Save current directory
    CURRENT_DIR="$PWD"
    cd "$BASELINE_DIR"
    
    # Run baseline coverage with same safe approach
    case "$REPO_TYPE" in
        schedule)
            if [ -d "schedule" ] && [ -f "schedule/__init__.py" ]; then
                timeout 60 coverage run --source=schedule -m pytest test*.py --tb=no --timeout=10 --timeout-method=thread > /dev/null 2>&1 || true
                BASELINE_COVERAGE=$(coverage report 2>/dev/null | grep "TOTAL" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
            fi
            ;;
        mistune)
            if [ -d "src/mistune" ]; then
                timeout 60 bash -c "PYTHONPATH=src:$PYTHONPATH coverage run --source=src/mistune -m pytest tests/ --tb=no --timeout=10 --timeout-method=thread" > /dev/null 2>&1 || true
            elif [ -d "mistune" ]; then
                timeout 60 coverage run --source=mistune -m pytest tests/ --tb=no --timeout=10 --timeout-method=thread > /dev/null 2>&1 || true
            fi
            BASELINE_COVERAGE=$(coverage report 2>/dev/null | grep "TOTAL" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
            ;;
        click)
            # For baseline click, just use pytest-cov
            TEMP_OUTPUT=$(mktemp)
            timeout 60 python -m pytest tests/ --cov=click --cov-report=term --tb=no --timeout=10 --timeout-method=thread > "$TEMP_OUTPUT" 2>&1 || true
            BASELINE_COVERAGE=$(grep "TOTAL" "$TEMP_OUTPUT" | grep -oE "[0-9]+%" | head -1 | tr -d '%' || echo 0)
            rm -f "$TEMP_OUTPUT"
            ;;
    esac
    
    BASELINE_COVERAGE=${BASELINE_COVERAGE:-0}
    echo "  Baseline coverage: ${BASELINE_COVERAGE}%"
    
    COVERAGE_INCREASE=$((COVERAGE_PCT - BASELINE_COVERAGE))
    if [ $COVERAGE_INCREASE -gt 0 ]; then
        echo -e "${GREEN}  Coverage improvement: +${COVERAGE_INCREASE}%${NC}"
    else
        echo -e "${YELLOW}  Coverage change: ${COVERAGE_INCREASE}%${NC}"
    fi
    
    cd "$CURRENT_DIR"
fi

# Generate JSON metrics (write to absolute path)
echo ""
echo -e "${CYAN}Generating metrics report...${NC}"

# Create temp file first
TEMP_OUTPUT=$(mktemp)

cat > "$TEMP_OUTPUT" <<EOF
{
  "repository": "$REPO_TYPE",
  "test_directory": "$TEST_DIR",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "metrics": {
    "test_functions": $TEST_FUNCTIONS,
    "test_lines": $TEST_LINES,
    "tests_passed": $TESTS_PASSED,
    "tests_failed": $TESTS_FAILED,
    "pass_rate": $PASS_RATE,
    "line_coverage": $COVERAGE_PCT,
    "branch_coverage": ${BRANCH_PCT:-0},
    "mutation_score": 0
  }
EOF

if [ -n "$BASELINE_DIR" ]; then
    # Ensure all baseline variables have defaults
    BASELINE_FUNCTIONS=${BASELINE_FUNCTIONS:-0}
    BASELINE_LINES=${BASELINE_LINES:-0}
    BASELINE_COVERAGE=${BASELINE_COVERAGE:-0}
    FUNCTIONS_ADDED=${FUNCTIONS_ADDED:-0}
    LINES_ADDED=${LINES_ADDED:-0}
    COVERAGE_INCREASE=${COVERAGE_INCREASE:-0}
    
    cat >> "$TEMP_OUTPUT" <<EOF
,
  "baseline": {
    "directory": "$BASELINE_DIR",
    "test_functions": $BASELINE_FUNCTIONS,
    "test_lines": $BASELINE_LINES,
    "coverage": $BASELINE_COVERAGE
  },
  "improvements": {
    "functions_added": $FUNCTIONS_ADDED,
    "lines_added": $LINES_ADDED,
    "coverage_increase": $COVERAGE_INCREASE
  }
EOF
fi

cat >> "$TEMP_OUTPUT" <<EOF
}
EOF

# Move temp file to final destination (using absolute path)
mv "$TEMP_OUTPUT" "$OUTPUT_FILE"

echo -e "${GREEN}✓ Metrics saved to: $OUTPUT_FILE${NC}"

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"

# Use color coding for results
if [ "$PASS_RATE" = "100" ] || [ "$PASS_RATE" = "100.0" ]; then
    echo -e "Pass Rate:     ${GREEN}${PASS_RATE}%${NC}"
else
    echo -e "Pass Rate:     ${YELLOW}${PASS_RATE}%${NC}"
fi

if [ "$COVERAGE_PCT" -ge 80 ]; then
    echo -e "Coverage:      ${GREEN}${COVERAGE_PCT}%${NC}"
elif [ "$COVERAGE_PCT" -ge 60 ]; then
    echo -e "Coverage:      ${YELLOW}${COVERAGE_PCT}%${NC}"
else
    echo -e "Coverage:      ${RED}${COVERAGE_PCT}%${NC}"
fi

if [ -n "$BASELINE_DIR" ] && [ -n "$COVERAGE_INCREASE" ]; then
    if [ $COVERAGE_INCREASE -gt 0 ]; then
        echo -e "Improvement:   ${GREEN}+${COVERAGE_INCREASE}% coverage${NC}"
        echo -e "Tests Added:   ${GREEN}+${FUNCTIONS_ADDED} functions${NC}"
    else
        echo -e "Improvement:   ${YELLOW}${COVERAGE_INCREASE}% coverage${NC}"
    fi
fi

echo ""
exit 0