#!/bin/bash
# Benchmark runner for test suite refinement comparison
# Runs Claude Code with different models and strategies

set -e  # Exit on error
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Usage function
show_usage() {
    echo "Usage: $0 <benchmark_directory> [--timeout MINUTES] [--parallel]"
    echo ""
    echo "Arguments:"
    echo "  benchmark_directory  - Directory containing test_*_refine and test_*_base subdirs"
    echo ""
    echo "Options:"
    echo "  --timeout MINUTES   - Maximum time per test in minutes (default: 30)"
    echo "  --parallel          - Run tests in parallel (experimental)"
    echo "  --dry-run           - Show what would be run without executing"
    echo ""
    echo "Example:"
    echo "  $0 ./benchmark --timeout 45"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    show_usage
fi

BENCHMARK_DIR="$1"
TIMEOUT_MINUTES=30
PARALLEL=false
DRY_RUN=false

# Parse optional arguments
shift
while [ $# -gt 0 ]; do
    case "$1" in
        --timeout)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate benchmark directory
if [ ! -d "$BENCHMARK_DIR" ]; then
    echo -e "${RED}Error: Directory '$BENCHMARK_DIR' does not exist${NC}"
    exit 1
fi

# Convert to absolute path
BENCHMARK_DIR="$(cd "$BENCHMARK_DIR" && pwd)"

# Model configurations
# Based on Claude documentation, using full model names
SONNET_MODEL="claude-sonnet-4-5-20250929"  # Latest Sonnet 4.5
OPUS_MODEL="claude-opus-4-1-20250805"      # Latest Opus 4.1

# Create results directory
RESULTS_DIR="$BENCHMARK_DIR/results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"
LOG_FILE="$RESULTS_DIR/benchmark.log"

# Log function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Create base prompt for non-refine strategy
create_base_prompt() {
    cat > "$1" <<'EOF'
# Test Suite Improvement Task

Your goal is to improve the test coverage and quality of this codebase.

## Objectives:
1. Analyze the existing test suite and identify gaps
2. Increase code coverage to at least 80%
3. Add tests for edge cases and error conditions
4. Ensure all critical paths are tested

## Steps to follow:
1. First, run the existing tests and measure coverage
2. Identify which files and functions have low coverage
3. Write new tests to cover the gaps
4. Focus on:
   - Boundary conditions
   - Error handling
   - Edge cases
   - Main execution paths

## Guidelines:
- Write clear, maintainable tests
- Use appropriate testing frameworks (pytest, jest, etc.)
- Include both positive and negative test cases
- Add comments explaining what each test validates

Please analyze the codebase and systematically improve the test suite to achieve comprehensive coverage.

Start by examining the current test coverage and then write the missing tests.
EOF
}

# Function to run a single test configuration
run_test_configuration() {
    local TEST_DIR="$1"
    local MODEL="$2"
    local MODEL_NAME="$3"
    local STRATEGY="$4"
    local OUTPUT_DIR="$5"
    
    if [ ! -d "$TEST_DIR" ]; then
        log "${YELLOW}Warning: Directory $TEST_DIR does not exist, skipping${NC}"
        return 1
    fi
    
    log "${CYAN}Running: $MODEL_NAME with $STRATEGY strategy${NC}"
    log "  Directory: $TEST_DIR"
    log "  Model: $MODEL"
    
    # Create output directory for this run
    RUN_OUTPUT="$OUTPUT_DIR/${MODEL_NAME}_${STRATEGY}"
    mkdir -p "$RUN_OUTPUT"
    
    # Copy the test directory to preserve original
    WORK_DIR="$RUN_OUTPUT/workspace"
    cp -r "$TEST_DIR" "$WORK_DIR"
    
    # Change to working directory
    cd "$WORK_DIR"
    
    # Prepare the command
    if [ "$STRATEGY" = "refine" ]; then
        # Use the refine-tests command
        PROMPT="/refine-tests auto"
    else
        # Use base prompt
        create_base_prompt "$WORK_DIR/test_prompt.txt"
        PROMPT="$(cat "$WORK_DIR/test_prompt.txt")"
    fi
    
    # Build the Claude command
    CLAUDE_CMD="claude --model $MODEL"
    
    # Add print mode for non-interactive execution
    CLAUDE_CMD="$CLAUDE_CMD --print"
    
    # Set permission mode to bypass for automated testing
    CLAUDE_CMD="$CLAUDE_CMD --dangerously-skip-permissions"
    
    # Add the prompt
    CLAUDE_CMD="$CLAUDE_CMD \"$PROMPT\""
    
    if [ "$DRY_RUN" = true ]; then
        log "${BLUE}[DRY RUN] Would execute:${NC}"
        log "  cd $WORK_DIR"
        log "  $CLAUDE_CMD"
        return 0
    fi
    
    # Run with timeout
    log "  Starting execution (timeout: ${TIMEOUT_MINUTES} minutes)..."
    
    # Execute and capture output
    STDOUT_FILE="$RUN_OUTPUT/stdout.log"
    STDERR_FILE="$RUN_OUTPUT/stderr.log"
    TIMING_FILE="$RUN_OUTPUT/timing.txt"
    
    # Start timing
    START_TIME=$(date +%s)
    
    # Run Claude with timeout
    if timeout "${TIMEOUT_MINUTES}m" bash -c "$CLAUDE_CMD" > "$STDOUT_FILE" 2> "$STDERR_FILE"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo "Duration: ${DURATION} seconds" > "$TIMING_FILE"
        log "  ${GREEN}✓ Completed successfully in ${DURATION} seconds${NC}"
        
        # Extract coverage metrics if available
        extract_metrics "$WORK_DIR" "$RUN_OUTPUT/metrics.json"
        
        return 0
    else
        EXIT_CODE=$?
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo "Duration: ${DURATION} seconds (timeout/error)" > "$TIMING_FILE"
        
        if [ $EXIT_CODE -eq 124 ]; then
            log "  ${YELLOW}⚠ Timeout after ${TIMEOUT_MINUTES} minutes${NC}"
        else
            log "  ${RED}✗ Failed with exit code $EXIT_CODE${NC}"
        fi
        return $EXIT_CODE
    fi
}

# Function to extract metrics from test results
extract_metrics() {
    local WORK_DIR="$1"
    local OUTPUT_FILE="$2"
    
    # Try to extract Python coverage
    if [ -f "$WORK_DIR/.coverage" ]; then
        coverage report --format=json -o "$OUTPUT_FILE" 2>/dev/null || true
    fi
    
    # Try to extract JavaScript coverage
    if [ -d "$WORK_DIR/coverage" ]; then
        cp "$WORK_DIR/coverage/coverage-final.json" "$OUTPUT_FILE" 2>/dev/null || true
    fi
    
    # Look for custom metrics in CLAUDE.md
    if [ -f "$WORK_DIR/CLAUDE.md" ]; then
        grep -E "Coverage:.*[0-9]+%" "$WORK_DIR/CLAUDE.md" > "$OUTPUT_FILE.coverage" 2>/dev/null || true
    fi
}

# Function to run all tests for a repository
run_repository_tests() {
    local REPO_NAME="$1"
    local REPO_OUTPUT="$RESULTS_DIR/$REPO_NAME"
    mkdir -p "$REPO_OUTPUT"
    
    log ""
    log "${BLUE}═══════════════════════════════════════════${NC}"
    log "${BLUE}Testing repository: $REPO_NAME${NC}"
    log "${BLUE}═══════════════════════════════════════════${NC}"
    
    # Test configurations
    local CONFIGS=(
        "test_sonnet-4-5_refine:$SONNET_MODEL:sonnet-4-5:refine"
        "test_sonnet-4-5_base:$SONNET_MODEL:sonnet-4-5:base"
        "test_opus-4-1_refine:$OPUS_MODEL:opus-4-1:refine"
        "test_opus-4-1_base:$OPUS_MODEL:opus-4-1:base"
    )
    
    local SUCCESS_COUNT=0
    local TOTAL_COUNT=0
    
    for CONFIG in "${CONFIGS[@]}"; do
        IFS=':' read -r DIR MODEL MODEL_NAME STRATEGY <<< "$CONFIG"
        TEST_DIR="$BENCHMARK_DIR/$DIR/$REPO_NAME"
        
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        
        if run_test_configuration "$TEST_DIR" "$MODEL" "$MODEL_NAME" "$STRATEGY" "$REPO_OUTPUT"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    done
    
    log ""
    log "Repository $REPO_NAME: $SUCCESS_COUNT/$TOTAL_COUNT configurations completed"
}

# Main execution
main() {
    log "${GREEN}═══════════════════════════════════════════${NC}"
    log "${GREEN}    Test Suite Refinement Benchmark${NC}"
    log "${GREEN}═══════════════════════════════════════════${NC}"
    log ""
    log "Configuration:"
    log "  Benchmark directory: $BENCHMARK_DIR"
    log "  Timeout: $TIMEOUT_MINUTES minutes per test"
    log "  Parallel execution: $PARALLEL"
    log "  Results directory: $RESULTS_DIR"
    log ""
    log "Models:"
    log "  Sonnet 4.5: $SONNET_MODEL"
    log "  Opus 4.1: $OPUS_MODEL"
    log ""
    
    # Find all repositories (subdirectories in one of the test dirs)
    SAMPLE_DIR=$(find "$BENCHMARK_DIR" -type d -name "test_*_*" | head -1)
    if [ -z "$SAMPLE_DIR" ]; then
        log "${RED}Error: No test directories found in $BENCHMARK_DIR${NC}"
        log "Expected structure: test_<model>_<strategy>/<repo_name>"
        exit 1
    fi
    
    # Get list of repositories
    REPOS=()
    for REPO_DIR in "$SAMPLE_DIR"/*; do
        if [ -d "$REPO_DIR" ]; then
            REPO_NAME=$(basename "$REPO_DIR")
            REPOS+=("$REPO_NAME")
        fi
    done
    
    if [ ${#REPOS[@]} -eq 0 ]; then
        log "${RED}Error: No repository directories found${NC}"
        exit 1
    fi
    
    log "Found ${#REPOS[@]} repositories to test: ${REPOS[*]}"
    log ""
    
    # Record start time
    BENCHMARK_START=$(date +%s)
    
    # Run tests for each repository
    if [ "$PARALLEL" = true ]; then
        log "${YELLOW}Parallel execution not yet implemented, running sequentially${NC}"
    fi
    
    for REPO in "${REPOS[@]}"; do
        run_repository_tests "$REPO"
    done
    
    # Calculate total time
    BENCHMARK_END=$(date +%s)
    TOTAL_TIME=$((BENCHMARK_END - BENCHMARK_START))
    TOTAL_MINUTES=$((TOTAL_TIME / 60))
    TOTAL_SECONDS=$((TOTAL_TIME % 60))
    
    # Generate summary report
    generate_summary_report
    
    log ""
    log "${GREEN}═══════════════════════════════════════════${NC}"
    log "${GREEN}Benchmark Complete!${NC}"
    log "Total time: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
    log "Results saved to: $RESULTS_DIR"
    log "${GREEN}═══════════════════════════════════════════${NC}"
}

# Generate summary report
generate_summary_report() {
    local SUMMARY_FILE="$RESULTS_DIR/summary.md"
    
    cat > "$SUMMARY_FILE" <<EOF
# Test Suite Refinement Benchmark Results

Generated: $(date)

## Configuration
- Benchmark Directory: $BENCHMARK_DIR
- Timeout per test: $TIMEOUT_MINUTES minutes
- Models tested:
  - Sonnet 4.5: $SONNET_MODEL
  - Opus 4.1: $OPUS_MODEL

## Results Summary

| Repository | Model | Strategy | Status | Duration | Coverage |
|------------|-------|----------|--------|----------|----------|
EOF
    
    # Add results for each test
    for REPO in "${REPOS[@]}"; do
        for CONFIG in "sonnet-4-5:refine" "sonnet-4-5:base" "opus-4-1:refine" "opus-4-1:base"; do
            IFS=':' read -r MODEL STRATEGY <<< "$CONFIG"
            
            RESULT_DIR="$RESULTS_DIR/$REPO/${MODEL}_${STRATEGY}"
            if [ -d "$RESULT_DIR" ]; then
                # Extract status
                if [ -f "$RESULT_DIR/timing.txt" ]; then
                    if grep -q "timeout" "$RESULT_DIR/timing.txt"; then
                        STATUS="Timeout"
                    else
                        STATUS="Complete"
                    fi
                    DURATION=$(grep "Duration:" "$RESULT_DIR/timing.txt" | cut -d' ' -f2)
                else
                    STATUS="Not run"
                    DURATION="-"
                fi
                
                # Try to extract coverage
                COVERAGE="-"
                if [ -f "$RESULT_DIR/metrics.json.coverage" ]; then
                    COVERAGE=$(grep -oE "[0-9]+%" "$RESULT_DIR/metrics.json.coverage" | head -1)
                fi
                
                echo "| $REPO | $MODEL | $STRATEGY | $STATUS | ${DURATION}s | $COVERAGE |" >> "$SUMMARY_FILE"
            fi
        done
    done
    
    cat >> "$SUMMARY_FILE" <<EOF

## Detailed Logs

Individual test logs can be found in the respective subdirectories:
- \`<repo>/<model>_<strategy>/stdout.log\` - Claude output
- \`<repo>/<model>_<strategy>/stderr.log\` - Error messages
- \`<repo>/<model>_<strategy>/workspace/\` - Final code state

## Notes

This benchmark compares two approaches:
1. **Refine Strategy**: Uses the sophisticated /refine-tests command with multi-phase analysis
2. **Base Strategy**: Simple prompt asking to improve test coverage

The goal is to measure the effectiveness of the structured refinement approach versus a basic prompt.
EOF
    
    log ""
    log "Summary report generated: $SUMMARY_FILE"
}

# Run main function
main