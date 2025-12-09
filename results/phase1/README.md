# Phase 1: Base vs Refine Comparison

## Overview

Phase 1 compared two test generation strategies:
- **Base**: Minimal prompt asking to "improve test coverage"
- **Refine**: Full `/refine-tests` multi-phase workflow with coverage analysis and mutation testing

## Repositories Tested

All three repositories had tests artificially removed to create coverage gaps:

1. **schedule** - Job scheduling library
2. **mistune** - Markdown parser
3. **click** - CLI toolkit

## Models

- Claude Sonnet 4.5 (`sonnet-4-5`)
- Claude Opus 4.1 (`opus-4-1`)

## Results Summary

| Repo | Model | Strategy | Coverage | Pass Rate | Tokens |
|------|-------|----------|----------|-----------|--------|
| schedule | Sonnet | base | 88% | 100.0% | 2.9M |
| schedule | Sonnet | refine | 85% | 72.5% | 4.9M |
| schedule | Opus | base | 91% | 100.0% | 3.2M |
| schedule | Opus | refine | 90% | 96.8% | 6.0M |
| mistune | Sonnet | base | 79% | 94.6% | 6.0M |
| mistune | Sonnet | refine | 72% | 85.0% | 5.6M |
| mistune | Opus | base | 76% | 94.3% | 4.2M |
| mistune | Opus | refine | 71% | 97.7% | 7.9M |
| click | Sonnet | base | 64% | 100.0% | 2.4M |
| click | Sonnet | refine | 64% | 91.4% | 8.2M |
| click | Opus | base | 67% | 91.9% | 10.6M |
| click | Opus | refine | 66% | 95.5% | 3.3M |

## Key Findings

1. Base matched or exceeded Refine coverage in 10 of 12 configurations
2. Base showed higher pass rates, often reaching 100%
3. Sonnet performed comparably to Opus at lower cost
4. Refine used 40-70% more tokens without apparent coverage benefit

## Files

- `summary.json` - Complete metrics for all 12 configurations
- `summary-plot.png` - Visualization comparing all configurations
