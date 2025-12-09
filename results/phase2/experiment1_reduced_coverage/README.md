# Phase 2, Experiment 1: Reduced Coverage Repositories

## Overview

Tested six prompt variants on repositories with tests artificially removed.

## Repositories

1. **click** - CLI toolkit (pallets/click)
2. **mistune** - Markdown parser (lepture/mistune)
3. **schedule** - Job scheduling library (dbader/schedule)

## Prompt Variants

| Variant | Lines | Context | Coverage | Mutations |
|---------|-------|---------|----------|-----------|
| V1-baseline | 30 | - | - | - |
| V2-baseline-context | 40 | Yes | - | - |
| V3-context-coverage | 60 | Yes | Yes | - |
| V4-context-mutations | 60 | Yes | - | Yes |
| V5-context-both | 80 | Yes | Yes | Yes |
| V6-minimal | 15 | Yes | - | - |

## Key Findings

- **V6 (Minimal)** achieved competitive coverage with ~50% fewer tokens
- **V4 (+Mutations)** sometimes reduced coverage, showing negative efficiency
- Best coverage efficiency: V2-Baseline+Context at ~30,303 points/Mtoken

## Files

- `metrics.json` - Complete metrics for all variant×repo combinations
- `RESULTS_SUMMARY.md` - Detailed analysis and recommendations
- `figures/` - Visualizations:
  - `combined_visualization.pdf` - Multi-panel summary
  - `coverage.png` - Final coverage by variant/repo
  - `coverage_efficiency.png` - Coverage gain per million tokens
  - `test_passfall.png` - Pass/fail counts
  - `token_usage.png` - Total tokens used
  - `tokens_per_test.png` - Efficiency per test
  - `runtime.png` - Execution time
  - `function_calls.png` - Tool invocation counts
  - `tool_breakdown.png` - Which tools were used
  - `bash_breakdown.png` - Bash command types
