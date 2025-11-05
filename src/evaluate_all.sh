#!/bin/bash
# Comprehensive evaluation script for test suite refinement benchmarks
# Processes workspaces, extracts metrics, and analyzes Claude token usage

set -e
set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Usage function
show_usage() {
    echo "Usage: $0 <benchmark_dir> [--output-dir <dir>]"
    echo ""
    echo "Arguments:"
    echo "  benchmark_dir    - Directory containing benchmark runs (e.g., ./bench)"
    echo ""
    echo "Options:"
    echo "  --output-dir DIR - Output directory for reports (default: ./evaluation_results)"
    echo "  --verbose        - Show detailed output"
    echo ""
    echo "Example:"
    echo "  $0 ./bench --output-dir ./results"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    show_usage
fi

BENCHMARK_DIR="$1"
shift

# Parse optional arguments
OUTPUT_DIR="./evaluation_results"
VERBOSE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
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

# Validate inputs
if [ ! -d "$BENCHMARK_DIR" ]; then
    echo -e "${RED}Error: Directory '$BENCHMARK_DIR' does not exist${NC}"
    exit 1
fi

# Get absolute paths
BENCHMARK_DIR="$(cd "$BENCHMARK_DIR" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# First check for evaluate.sh in src directory
if [ -f "${SCRIPT_DIR}/evaluate.sh" ]; then
    EVALUATE_SCRIPT="${SCRIPT_DIR}/evaluate.sh"
elif [ -f "${SCRIPT_DIR}/../src/evaluate.sh" ]; then
    EVALUATE_SCRIPT="${SCRIPT_DIR}/../src/evaluate.sh"
else
    echo -e "${RED}Error: evaluate.sh not found${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="$OUTPUT_DIR/evaluation_$TIMESTAMP"
mkdir -p "$REPORT_DIR"

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Comprehensive Benchmark Evaluation${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""
echo "Benchmark directory: $BENCHMARK_DIR"
echo "Output directory: $REPORT_DIR"
echo ""

# Function to extract token usage from JSONL file
extract_token_usage() {
    local JSONL_FILE="$1"
    local OUTPUT_FILE="$2"
    
    if [ ! -f "$JSONL_FILE" ]; then
        echo "{\"error\": \"File not found\"}" > "$OUTPUT_FILE"
        return 1
    fi
    
    # Use Python to parse JSONL and extract token usage
    python3 <<EOF > "$OUTPUT_FILE"
import json
import sys

total_input = 0
total_output = 0
total_cache_creation = 0
total_cache_read = 0
message_count = 0

try:
    with open("$JSONL_FILE", 'r') as f:
        for line in f:
            try:
                data = json.loads(line)
                if 'message' in data and isinstance(data['message'], dict):
                    msg = data['message']
                    if 'usage' in msg and isinstance(msg['usage'], dict):
                        usage = msg['usage']
                        message_count += 1
                        
                        # Add up different token types
                        total_input += usage.get('input_tokens', 0)
                        total_output += usage.get('output_tokens', 0)
                        total_cache_creation += usage.get('cache_creation_input_tokens', 0)
                        total_cache_read += usage.get('cache_read_input_tokens', 0)
            except json.JSONDecodeError:
                continue
    
    # Calculate totals
    total_tokens = total_input + total_output + total_cache_creation + total_cache_read
    
    result = {
        "file": "$JSONL_FILE",
        "message_count": message_count,
        "tokens": {
            "total": total_tokens,
            "input": total_input,
            "output": total_output,
            "cache_creation": total_cache_creation,
            "cache_read": total_cache_read
        }
    }
    
    print(json.dumps(result, indent=2))
except Exception as e:
    print(json.dumps({"error": str(e)}))
EOF
}

# Function to find Claude log for a workspace
find_claude_log() {
    local WORKSPACE_PATH="$1"
    local REPO="$2"
    local MODEL="$3"
    local STRATEGY="$4"
    
    # Extract the benchmark name and timestamp from the path
    # Path looks like: /path/to/bench/bench1/results_20250930_165335/schedule/sonnet-4-5_refine/workspace
    local BENCH_NAME=$(echo "$WORKSPACE_PATH" | grep -oP 'bench\d+' | head -1)
    local TIMESTAMP=$(echo "$WORKSPACE_PATH" | grep -oP 'results_\d{8}_\d{6}' | head -1)
    
    # Convert timestamp format from results_20250930_165335 to 20250930-165335
    local TIMESTAMP_CONVERTED=$(echo "$TIMESTAMP" | sed 's/results_//; s/_/-/')
    
    # Look for matching directories in .claude/projects/
    local CLAUDE_DIR="$HOME/.claude/projects"
    
    if [ "$VERBOSE" = true ]; then
        echo "      Looking for pattern with: bench=$BENCH_NAME, timestamp=$TIMESTAMP_CONVERTED, repo=$REPO, model=$MODEL, strategy=$STRATEGY" >&2
    fi
    
    if [ -d "$CLAUDE_DIR" ]; then
        # Build possible patterns to match
        # The actual pattern seems to be: *bench1*results*20250930-165335*schedule*sonnet-4-5*refine*workspace
        for DIR in "$CLAUDE_DIR"/*; do
            local DIRNAME=$(basename "$DIR")
            
            # Check if directory name contains all the key components
            if [[ "$DIRNAME" == *"$BENCH_NAME"* ]] && \
               [[ "$DIRNAME" == *"$TIMESTAMP_CONVERTED"* ]] && \
               [[ "$DIRNAME" == *"$REPO"* ]] && \
               [[ "$DIRNAME" == *"$MODEL"* ]] && \
               [[ "$DIRNAME" == *"$STRATEGY"* ]]; then
                
                # Look for JSONL file in this directory
                for JSONL in "$DIR"/*.jsonl; do
                    if [ -f "$JSONL" ]; then
                        if [ "$VERBOSE" = true ]; then
                            echo "      Found: $JSONL" >&2
                        fi
                        echo "$JSONL"  # Only output the actual path to stdout
                        return 0
                    fi
                done
            fi
        done
        
        # If not found with converted timestamp, try original format
        local TIMESTAMP_ORIGINAL=$(echo "$TIMESTAMP" | sed 's/results_//')
        
        for DIR in "$CLAUDE_DIR"/*; do
            local DIRNAME=$(basename "$DIR")
            
            if [[ "$DIRNAME" == *"$BENCH_NAME"* ]] && \
               [[ "$DIRNAME" == *"$TIMESTAMP_ORIGINAL"* ]] && \
               [[ "$DIRNAME" == *"$REPO"* ]] && \
               [[ "$DIRNAME" == *"$MODEL"* ]] && \
               [[ "$DIRNAME" == *"$STRATEGY"* ]]; then
                
                for JSONL in "$DIR"/*.jsonl; do
                    if [ -f "$JSONL" ]; then
                        if [ "$VERBOSE" = true ]; then
                            echo "      Found: $JSONL" >&2
                        fi
                        echo "$JSONL"  # Only output the actual path to stdout
                        return 0
                    fi
                done
            fi
        done
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "      Not found in: $CLAUDE_DIR" >&2
    fi
    
    return 1
}

# Initialize summary data
SUMMARY_FILE="$REPORT_DIR/summary.json"
echo "{" > "$SUMMARY_FILE"
echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",' >> "$SUMMARY_FILE"
echo '  "benchmarks": [' >> "$SUMMARY_FILE"

FIRST_BENCH=true

# Process each benchmark run
for BENCH_DIR in "$BENCHMARK_DIR"/bench*; do
    if [ ! -d "$BENCH_DIR" ]; then
        continue
    fi
    
    BENCH_NAME=$(basename "$BENCH_DIR")
    echo -e "${CYAN}Processing $BENCH_NAME...${NC}"
    
    # Find results directory
    RESULTS_DIR=$(find "$BENCH_DIR" -type d -name "results_*" | head -1)
    
    if [ -z "$RESULTS_DIR" ]; then
        echo -e "${YELLOW}  No results directory found in $BENCH_NAME${NC}"
        continue
    fi
    
    # Add comma if not first benchmark
    if [ "$FIRST_BENCH" = false ]; then
        echo "," >> "$SUMMARY_FILE"
    fi
    FIRST_BENCH=false
    
    echo "    {" >> "$SUMMARY_FILE"
    echo "      \"name\": \"$BENCH_NAME\"," >> "$SUMMARY_FILE"
    echo "      \"results_dir\": \"$RESULTS_DIR\"," >> "$SUMMARY_FILE"
    echo "      \"configurations\": [" >> "$SUMMARY_FILE"
    
    FIRST_CONFIG=true
    
    # Process each configuration
    for REPO in schedule mistune click; do
        for MODEL in sonnet-4-5; do
            for STRATEGY in refine base obra; do
                CONFIG_NAME="${MODEL}_${STRATEGY}"
                WORKSPACE="$RESULTS_DIR/$REPO/${CONFIG_NAME}/workspace"
                
                if [ ! -d "$WORKSPACE" ]; then
                    if [ "$VERBOSE" = true ]; then
                        echo -e "${YELLOW}  Workspace not found: $WORKSPACE${NC}"
                    fi
                    continue
                fi
                
                echo -e "  ${BLUE}Evaluating $REPO/$CONFIG_NAME...${NC}"
                
                # Create output directory for this configuration
                CONFIG_OUTPUT="$REPORT_DIR/$BENCH_NAME/$REPO/$CONFIG_NAME"
                mkdir -p "$CONFIG_OUTPUT"
                
                # Add comma if not first configuration
                if [ "$FIRST_CONFIG" = false ]; then
                    echo "," >> "$SUMMARY_FILE"
                fi
                FIRST_CONFIG=false
                
                echo "        {" >> "$SUMMARY_FILE"
                echo "          \"repository\": \"$REPO\"," >> "$SUMMARY_FILE"
                echo "          \"model\": \"$MODEL\"," >> "$SUMMARY_FILE"
                echo "          \"strategy\": \"$STRATEGY\"," >> "$SUMMARY_FILE"
                
                # Run evaluation
                METRICS_FILE="$CONFIG_OUTPUT/metrics.json"
                BASELINE_DIR="$BENCHMARK_DIR/$BENCH_NAME/test_${MODEL}_${STRATEGY}/$REPO"
                
                if bash "$EVALUATE_SCRIPT" "$WORKSPACE" "$REPO" \
                    --baseline "$BASELINE_DIR" \
                    --output "$METRICS_FILE" > "$CONFIG_OUTPUT/evaluate.log" 2>&1; then
                    
                    echo -e "    ${GREEN}✓ Evaluation complete${NC}"
                    
                    # Extract key metrics for summary
                    if [ -f "$METRICS_FILE" ]; then
                        COVERAGE=$(jq -r '.metrics.line_coverage // 0' "$METRICS_FILE")
                        PASS_RATE=$(jq -r '.metrics.pass_rate // 0' "$METRICS_FILE")
                        TESTS_ADDED=$(jq -r '.improvements.functions_added // 0' "$METRICS_FILE")
                        
                        echo "          \"coverage\": $COVERAGE," >> "$SUMMARY_FILE"
                        echo "          \"pass_rate\": $PASS_RATE," >> "$SUMMARY_FILE"
                        echo "          \"tests_added\": $TESTS_ADDED," >> "$SUMMARY_FILE"
                    fi
                else
                    echo -e "    ${RED}✗ Evaluation failed${NC}"
                    echo "          \"error\": \"Evaluation failed\"," >> "$SUMMARY_FILE"
                fi
                
                # Find and process Claude log
                echo -n "    Looking for Claude log... "
                if CLAUDE_LOG=$(find_claude_log "$WORKSPACE" "$REPO" "$MODEL" "$STRATEGY"); then
                    echo -e "${GREEN}found${NC}"
                    
                    # Copy log to output directory
                    cp "$CLAUDE_LOG" "$CONFIG_OUTPUT/claude.jsonl"
                    
                    # Extract token usage
                    TOKEN_FILE="$CONFIG_OUTPUT/token_usage.json"
                    extract_token_usage "$CLAUDE_LOG" "$TOKEN_FILE"
                    
                    if [ -f "$TOKEN_FILE" ]; then
                        TOTAL_TOKENS=$(jq -r '.tokens.total // 0' "$TOKEN_FILE")
                        echo "          \"tokens\": $TOTAL_TOKENS" >> "$SUMMARY_FILE"
                        echo -e "    ${CYAN}Total tokens: $TOTAL_TOKENS${NC}"
                    fi
                else
                    echo -e "${YELLOW}not found${NC}"
                    echo "          \"tokens\": null" >> "$SUMMARY_FILE"
                fi
                
                echo "        }" >> "$SUMMARY_FILE"
            done
        done
    done
    
    echo "      ]" >> "$SUMMARY_FILE"
    echo "    }" >> "$SUMMARY_FILE"
done

echo "  ]" >> "$SUMMARY_FILE"
echo "}" >> "$SUMMARY_FILE"

# Generate comprehensive token analysis
echo ""
echo -e "${CYAN}Generating comprehensive token analysis...${NC}"

TOKEN_REPORT="$REPORT_DIR/token_analysis.md"
python3 <<EOF > "$TOKEN_REPORT" 2>/dev/null
import json
import os
import sys
from pathlib import Path

report_dir = Path("$REPORT_DIR")

# Collect all token data
total_tokens = 0
tokens_by_model = {}
tokens_by_strategy = {}
tokens_by_repo = {}
detailed_results = []

for bench_dir in report_dir.glob("bench*"):
    for repo_dir in bench_dir.glob("*"):
        if not repo_dir.is_dir():
            continue
            
        repo = repo_dir.name
        
        # Skip if not a valid repo name
        if repo not in ['schedule', 'mistune', 'click']:
            continue
            
        for config_dir in repo_dir.glob("*"):
            if not config_dir.is_dir():
                continue
                
            config = config_dir.name
            token_file = config_dir / "token_usage.json"
            
            if token_file.exists():
                try:
                    with open(token_file) as f:
                        data = json.load(f)
                        
                    if 'tokens' in data:
                        tokens = data['tokens']
                        
                        # Parse config name: format is "model_strategy"
                        # where model can be "sonnet-4-5" or "opus-4-1" 
                        # and strategy is "refine" or "base"
                        if '_' in config:
                            # Split on last underscore to handle model names with hyphens
                            last_underscore = config.rfind('_')
                            if last_underscore > 0:
                                model = config[:last_underscore]
                                strategy = config[last_underscore+1:]
                            else:
                                # Fallback
                                parts = config.split('_')
                                model = '_'.join(parts[:-1])
                                strategy = parts[-1]
                        else:
                            # Should not happen but provide fallback
                            model = config
                            strategy = "unknown"
                        
                        # Add to totals
                        total = tokens['total']
                        total_tokens += total
                        
                        # By model
                        if model not in tokens_by_model:
                            tokens_by_model[model] = 0
                        tokens_by_model[model] += total
                        
                        # By strategy
                        if strategy not in tokens_by_strategy:
                            tokens_by_strategy[strategy] = 0
                        tokens_by_strategy[strategy] += total
                        
                        # By repo
                        if repo not in tokens_by_repo:
                            tokens_by_repo[repo] = 0
                        tokens_by_repo[repo] += total
                        
                        # Detailed results
                        detailed_results.append({
                            'bench': bench_dir.name,
                            'repo': repo,
                            'model': model,
                            'strategy': strategy,
                            'total': total,
                            'input': tokens['input'],
                            'output': tokens['output'],
                            'cache_creation': tokens['cache_creation'],
                            'cache_read': tokens['cache_read']
                        })
                except Exception as e:
                    print(f"Error processing {token_file}: {e}", file=sys.stderr)
                    continue

# Generate markdown report
print("# Token Usage Analysis")
print()
print(f"**Total Tokens Used**: {total_tokens:,}")
print()

if tokens_by_model:
    print("## By Model")
    for model, count in sorted(tokens_by_model.items()):
        pct = (count / total_tokens * 100) if total_tokens > 0 else 0
        print(f"- **{model}**: {count:,} tokens ({pct:.1f}%)")
    print()

if tokens_by_strategy:
    print("## By Strategy")
    for strategy, count in sorted(tokens_by_strategy.items()):
        pct = (count / total_tokens * 100) if total_tokens > 0 else 0
        print(f"- **{strategy}**: {count:,} tokens ({pct:.1f}%)")
    print()

if tokens_by_repo:
    print("## By Repository")
    for repo, count in sorted(tokens_by_repo.items()):
        pct = (count / total_tokens * 100) if total_tokens > 0 else 0
        print(f"- **{repo}**: {count:,} tokens ({pct:.1f}%)")
    print()

if detailed_results:
    print("## Detailed Breakdown")
    print()
    print("| Benchmark | Repository | Model | Strategy | Total | Input | Output | Cache Create | Cache Read |")
    print("|-----------|------------|-------|----------|-------|-------|--------|--------------|------------|")

    for result in sorted(detailed_results, key=lambda x: (x['bench'], x['repo'], x['model'], x['strategy'])):
        print(f"| {result['bench']} | {result['repo']} | {result['model']} | {result['strategy']} | "
              f"{result['total']:,} | {result['input']:,} | {result['output']:,} | "
              f"{result['cache_creation']:,} | {result['cache_read']:,} |")
EOF

# Generate final summary report
FINAL_REPORT="$REPORT_DIR/README.md"
cat > "$FINAL_REPORT" <<EOF
# Benchmark Evaluation Results

Generated: $(date)

## Overview

This directory contains comprehensive evaluation results for the test suite refinement benchmarks.

## Structure

\`\`\`
$REPORT_DIR/
├── README.md                 # This file
├── summary.json             # Machine-readable summary
├── token_analysis.md        # Token usage analysis
└── bench*/                  # Results by benchmark
    └── <repo>/              # Results by repository
        └── <model>_<strategy>/
            ├── metrics.json      # Test metrics
            ├── evaluate.log      # Evaluation output
            ├── claude.jsonl      # Claude session log
            └── token_usage.json  # Token usage data
\`\`\`

## Quick Stats

EOF

# Add quick stats from summary
python3 <<PYTHON >> "$FINAL_REPORT"
import json
with open("$SUMMARY_FILE") as f:
    data = json.load(f)
    
total_configs = sum(len(b['configurations']) for b in data['benchmarks'])
successful = sum(1 for b in data['benchmarks'] for c in b['configurations'] if 'error' not in c)

print(f"- **Total Configurations Evaluated**: {total_configs}")
print(f"- **Successful Evaluations**: {successful}")
print(f"- **Success Rate**: {(successful/total_configs*100) if total_configs > 0 else 0:.1f}%")
print()
print("## Key Findings")
print()

# Calculate averages by strategy
refine_coverage = []
base_coverage = []

for bench in data['benchmarks']:
    for config in bench['configurations']:
        if 'coverage' in config:
            if config['strategy'] == 'refine':
                refine_coverage.append(config['coverage'])
            else:
                base_coverage.append(config['coverage'])

if refine_coverage:
    avg_refine = sum(refine_coverage) / len(refine_coverage)
    print(f"- **Average Coverage (Refine Strategy)**: {avg_refine:.1f}%")
    
if base_coverage:
    avg_base = sum(base_coverage) / len(base_coverage)
    print(f"- **Average Coverage (Base Strategy)**: {avg_base:.1f}%")

if refine_coverage and base_coverage:
    improvement = avg_refine - avg_base
    print(f"- **Average Improvement (Refine vs Base)**: {improvement:+.1f}%")
PYTHON

echo "" >> "$FINAL_REPORT"
echo "## Token Usage Summary" >> "$FINAL_REPORT"
echo "" >> "$FINAL_REPORT"
echo "See [token_analysis.md](token_analysis.md) for detailed breakdown." >> "$FINAL_REPORT"
echo "" >> "$FINAL_REPORT"

# Extract token summary
if [ -f "$TOKEN_REPORT" ]; then
    grep "Total Tokens Used" "$TOKEN_REPORT" >> "$FINAL_REPORT"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Evaluation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo "Results saved to: $REPORT_DIR"
echo ""
echo "Key files:"
echo "  - Summary: $REPORT_DIR/summary.json"
echo "  - Token Analysis: $REPORT_DIR/token_analysis.md"
echo "  - Full Report: $REPORT_DIR/README.md"
echo ""

# Show quick summary
if [ -f "$SUMMARY_FILE" ]; then
    echo "Quick Summary:"
    python3 <<EOF
import json
with open("$SUMMARY_FILE") as f:
    data = json.load(f)
    
total_tokens = 0
total_configs = 0
total_coverage = []

for bench in data['benchmarks']:
    for config in bench['configurations']:
        total_configs += 1
        if 'tokens' in config and config['tokens']:
            total_tokens += config['tokens']
        if 'coverage' in config:
            total_coverage.append(config['coverage'])

print(f"  - Configurations evaluated: {total_configs}")
print(f"  - Total tokens used: {total_tokens:,}")
if total_coverage:
    print(f"  - Average coverage achieved: {sum(total_coverage)/len(total_coverage):.1f}%")
EOF
fi

exit 0