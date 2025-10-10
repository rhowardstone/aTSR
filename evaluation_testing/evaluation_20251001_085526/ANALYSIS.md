# Test Suite Refinement Experiment Analysis

**Date:** October 8, 2025
**Analyst:** Claude Sonnet 4.5

## Executive Summary

The "refine" strategy **UNDERPERFORMED** the "base" strategy across all metrics:
- **Coverage:** 74.7% (refine) vs 77.5% (base) = **-2.8% worse**
- **Token Usage:** 35.8M (refine) vs 29.3M (base) = **+22% more tokens**
- **Pass Rates:** Lower and more variable for refine (72-97%) vs base (often 100%)

The 860-line prescriptive prompt was **too complex** and distracted from the core task.

---

## Detailed Performance Comparison

### Coverage by Repository and Model

| Repository | Model | Strategy | Coverage | Pass Rate | Tests Added | Tokens |
|------------|-------|----------|----------|-----------|-------------|---------|
| **schedule** | sonnet-4-5 | base | **88%** ✓ | **100%** ✓ | 76 | 2.94M |
| schedule | sonnet-4-5 | refine | 85% | 72.5% | 216 | 4.93M |
| schedule | opus-4-1 | base | **91%** ✓ | **100%** ✓ | 94 | 3.19M |
| schedule | opus-4-1 | refine | 90% | 96.8% | 212 | 5.97M |
| **mistune** | sonnet-4-5 | base | **79%** ✓ | **94.6%** ✓ | 194 | 5.95M |
| mistune | sonnet-4-5 | refine | 72% | 85.0% | 258 | 5.56M |
| mistune | opus-4-1 | base | **76%** ✓ | 94.3% | 376 | 4.21M |
| mistune | opus-4-1 | refine | 71% | 97.7% | 300 | 7.93M |
| **click** | sonnet-4-5 | base | **64%** ✓ | **100%** ✓ | 234 | 2.37M |
| click | sonnet-4-5 | refine | 64% | 91.4% | 334 | 8.18M |
| click | opus-4-1 | base | **67%** ✓ | 91.9% | 212 | 10.6M |
| click | opus-4-1 | refine | 66% | 95.5% | 298 | 3.26M |

### Aggregate Statistics

**By Strategy:**
- Base: 77.5% avg coverage, 29.3M tokens (45%), often 100% pass rates
- Refine: 74.7% avg coverage, 35.8M tokens (55%), variable pass rates

**Win Rate:** Base won 8/12 configurations on coverage, 7/12 on pass rate

---

## Why Refine Failed

### 1. **Cognitive Overload**

The refine prompt is **860 lines** with:
- 6 phases (Environment → Coverage → Mutations → Generation → Properties → Verification)
- 4 size-based decision branches (< 100 LOC, 100-1000, 1000-5000, > 5000)
- Multiple tool setup scripts (mutmut, coverage, gcov, nyc, stryker, jacoco, pitest)
- Decision gates, expert heuristics, property test detection, AST analysis

**Result:** Models got lost in the workflow instead of focusing on writing tests.

**Evidence:**
- Mistune refine: "This falls in the 'Full Workflow' category (>5000 lines)" → triggered unnecessary complexity
- Schedule refine: 43 tool uses vs 40 for base (similar, but different focus)
- Lower pass rates suggest rushed or lower-quality tests

### 2. **Token Waste on Tooling**

Refine used 22% more tokens but achieved 2.8% WORSE coverage.

**Where tokens went:**
- Reading 860-line prompt (cache creation)
- Bash scripts for tool detection and setup
- Decision-making about which workflow to follow
- Generating elaborate analysis reports
- Setting up mutation testing infrastructure

**What base did instead:**
- Immediately started analyzing code
- Focused on writing tests
- Used tokens efficiently on actual test code

### 3. **Analysis Paralysis**

Refine's "expert heuristics" and "decision matrices" created analysis paralysis:

```markdown
| Code Size | Approach | Time | Description |
|-----------|----------|------|-------------|
| < 100 lines | Direct Fix | 2-5 min | ... |
| 100-1000 lines | Light Touch | 5-15 min | ... |
| 1000-5000 lines | Standard | 15-30 min | ... |
| > 5000 lines | Full Workflow | 30+ min | ... |
```

**Problem:** Real repos don't fit neat categories. Mistune at ~5000 LOC triggered "Full Workflow" but that was overkill.

### 4. **Misdirected Effort**

Refine added MORE tests (212-334) but achieved LOWER coverage than base (76-234 tests).

**Interpretation:**
- Refine tests were less targeted
- Focus on quantity over quality
- Time wasted on framework setup instead of gap identification

---

## What Base Did Right

### 1. **Simplicity and Focus**

30-line prompt with 4 clear objectives:
1. Analyze existing suite and identify gaps
2. Increase coverage to 80%
3. Add tests for edge cases and errors
4. Ensure critical paths tested

**No decision trees, no size assessments, no tool selection scripts.**

### 2. **Immediate Action**

First response: "I'll analyze the codebase and systematically improve the test suite. Let me start..."

**vs Refine's first response:** Reading 860 lines, deciding which workflow applies, running LOC counting scripts.

### 3. **Efficient Token Allocation**

Base used tokens on:
- Understanding the codebase structure
- Running coverage early
- Identifying specific gaps
- Writing targeted tests
- Verifying improvements

### 4. **Flexible Adaptation**

Without rigid frameworks, base adapted to each repository's needs:
- Schedule: Focused on scheduler methods and job lifecycle
- Mistune: Targeted plugins and parsers
- Click: Addressed CLI and completion systems

---

## Key Principles Discovered

### ✅ DO:
1. **Start simple** - Clear objectives, immediate action
2. **Measure first** - Run coverage early, identify gaps
3. **Target gaps** - Write tests for uncovered code, not everything
4. **Verify incrementally** - Check progress after each batch
5. **Focus on quality** - 100% pass rate matters more than test count

### ❌ DON'T:
1. **Overcomplicate** - 860-line prompts create cognitive load
2. **Categorize prematurely** - Repos don't fit neat size brackets
3. **Setup elaborate tooling** - Mutation testing is overkill for initial refinement
4. **Follow rigid workflows** - Flexibility > prescribed phases
5. **Waste tokens on framework** - Writing tests > writing about testing

---

## Recommendations for Improved Prompts

### Core Philosophy

> **"Orient, then act."**
>
> Before Claude starts, give it **compact, actionable context** via pre-execution commands. Then keep the prompt **focused and directive**.

### Pre-Execution Context Gathering

Use bash commands that **echo directive information** based on repo characteristics:

```bash
#!/bin/bash
# Pre-execution context script (runs BEFORE prompt is shown)

# 1. Detect language (GitHub Linguist style)
LANG=$(find . -name "*.py" | wc -l)
if [ $LANG -gt 0 ]; then
    echo "!LANGUAGE: Python"
    echo "!TEST_RUNNER: pytest"
    echo "!COVERAGE_CMD: coverage run -m pytest"
fi

# 2. Assess size (but simple)
CODE_FILES=$(find . -type f -name "*.py" ! -path "*/test*" | wc -l)
CODE_LINES=$(find . -type f -name "*.py" ! -path "*/test*" -exec wc -l {} + | tail -1 | awk '{print $1}')
echo "!SIZE: $CODE_FILES files, $CODE_LINES LOC"

# 3. Find test structure
if [ -d "tests" ]; then
    echo "!TEST_DIR: tests/"
elif [ -f "test_*.py" ]; then
    echo "!TEST_DIR: . (root)"
fi

# 4. Quick coverage check
coverage run -m pytest 2>/dev/null
INITIAL_COV=$(coverage report 2>/dev/null | grep TOTAL | awk '{print $4}' | tr -d '%')
echo "!INITIAL_COVERAGE: ${INITIAL_COV:-unknown}%"
```

**Benefits:**
- Claude receives **oriented context** without wasting tokens discovering it
- Conditional directives based on actual repo state
- No rigid decision matrices in prompt
- Faster time-to-first-test

### Improved Prompt Structure

See `improved-prompts/` directory for specific variants.

---

## Proposed Prompt Variants

I will generate 5 variants to test:

1. **`improved-base.md`** - Base prompt + pre-execution context
2. **`focused-coverage.md`** - Emphasizes coverage gaps only, no mutations
3. **`adaptive-depth.md`** - Simple prompt that self-adjusts based on progress
4. **`expert-patterns.md`** - Short list of test patterns (not a workflow)
5. **`minimal-directive.md`** - Ultra-concise, trusting Claude's judgment

Each variant prioritizes:
- **Brevity** (< 100 lines)
- **Clarity** (direct objectives)
- **Action-orientation** (start testing immediately)
- **Pre-execution context** (bash commands gather info upfront)

---

## Next Steps

1. Create `improved-prompts/` directory with 5 variants
2. Create pre-execution scripts for context gathering
3. Document testing protocol for variants
4. Update CLAUDE.md with findings and approach
