# Phase 2, Experiment 2: Low Existing Coverage Repositories

## Overview

Tested six prompt variants on repositories with naturally low test coverage (no artificial test removal).

## Repositories

1. **python-box** - Dictionary wrapper with attribute access (cdgriffith/Box)
   - Baseline coverage: ~2%
2. **colorama** - Cross-platform terminal colors (tartley/colorama)
   - Baseline coverage: ~70%
3. **boltons** - Utility functions library (mahmoud/boltons)
   - Baseline coverage: ~70%

## Prompt Variants

Same six variants as Experiment 1 (V1-V6).

## Key Findings

- **python-box** showed dramatic improvement (2% to 80-90%) across all variants
- **colorama** and **boltons** showed modest gains (ceiling effect at ~70% baseline)
- V6 (Minimal) achieved 83% coverage on python-box with 3.0M tokens (~27 points/Mtoken)

## Files

- `metrics.json` - Complete metrics for all variant×repo combinations
- `figures/` - Visualizations (same structure as Experiment 1)
