# Benchmark Evaluation Results

Generated: Wed Oct  1 08:57:37 AM EDT 2025

## Overview

This directory contains comprehensive evaluation results for the test suite refinement benchmarks.

## Structure

```
/atb-data/5095_project/cloned/aTSR/evaluation_testing3/evaluation_20251001_085526/
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
```

## Quick Stats

- **Total Configurations Evaluated**: 12
- **Successful Evaluations**: 12
- **Success Rate**: 100.0%

## Key Findings

- **Average Coverage (Refine Strategy)**: 74.7%
- **Average Coverage (Base Strategy)**: 77.5%
- **Average Improvement (Refine vs Base)**: -2.8%

See [ANALYSIS.md](ANALYSIS.md) for autopsy of this attempt.

## Token Usage Summary

See [token_analysis.md](token_analysis.md) for detailed breakdown of token usage.

**Total Tokens Used**: 65,117,313
