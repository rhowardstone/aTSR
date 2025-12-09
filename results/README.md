# aTSR Experimental Results

This directory contains all experimental results from the aTSR (Agentic Test Suite Refinement) study.

## Directory Structure

```
results/
├── phase1/                              # Phase 1: Base vs Refine comparison
│   ├── summary.json                     # Metrics for all 12 configurations
│   └── summary-plot.png                 # Visualization of Phase 1 results
│
└── phase2/                              # Phase 2: Six prompt variants (V1-V6)
    ├── experiment1_reduced_coverage/    # click, mistune, schedule
    ├── experiment2_low_existing_coverage/ # python-box, colorama, boltons
    └── experiment3_bioinformatics/      # dnaapler, fastqe, pyfaidx
```

## Phase 1: Base vs Refine

Compared two strategies across three "reduced coverage" repositories:
- **Base**: Simple prompt asking to "improve test coverage"
- **Refine**: Full `/refine-tests` multi-phase workflow

Models tested: Claude Sonnet 4.5, Claude Opus 4.1

**Key finding**: Base strategy matched or exceeded Refine in most configurations while using fewer tokens.

## Phase 2: Six Prompt Variants

Tested factorial design of prompt components:

| Variant | Description | Context | Coverage | Mutations |
|---------|-------------|---------|----------|-----------|
| V1 | Baseline (control) | - | - | - |
| V2 | +Context | Yes | - | - |
| V3 | +Coverage | Yes | Yes | - |
| V4 | +Mutations | Yes | - | Yes |
| V5 | +Both | Yes | Yes | Yes |
| V6 | Minimal | Yes | - | - |

### Experiment 1: Reduced Coverage Repos
Repositories with tests artificially removed: click, mistune, schedule

### Experiment 2: Low Existing Coverage Repos
Repositories with naturally low coverage: python-box, colorama, boltons

### Experiment 3: Bioinformatics Repos
Domain-specific repositories: dnaapler, fastqe, pyfaidx

## File Formats

- `metrics.json`: Complete extracted metrics including coverage, pass rates, token usage, tool calls
- `figures/combined_visualization.pdf`: Multi-panel visualization of all metrics
- `figures/*.png`: Individual metric visualizations
