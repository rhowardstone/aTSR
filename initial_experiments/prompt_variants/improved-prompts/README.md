# Improved Test Refinement Prompts

This directory contains 6 systematically designed prompt variants for test suite refinement, based on analysis of the original experiment where the "refine" strategy underperformed "base" by 2.8% coverage while using 22% more tokens.

## Quick Start

### Installation

Copy the variant you want to test to Claude Code's command directory:

```bash
# For project-specific commands:
cp v2-baseline-context.md /path/to/your/project/.claude/commands/refine-tests.md

# For personal commands (available in all projects):
cp v2-baseline-context.md ~/.claude/commands/refine-tests.md
```

### Usage

```bash
cd your-project
claude

> /refine-tests
```

---

## Variant Overview

| Variant | Pre-Exec | Coverage | Mutations | Lines | Use When |
|---------|----------|----------|-----------|-------|----------|
| **V1** | ❌ | ❌ | ❌ | 30 | Control / baseline comparison |
| **V2** | ✅ | ❌ | ❌ | 40 | **Recommended default** |
| **V3** | ✅ | ✅ | ❌ | 60 | Need systematic gap identification |
| **V4** | ✅ | ❌ | ✅ | 60 | Have good coverage, need quality |
| **V5** | ✅ | ✅ | ✅ | 80 | Comprehensive refinement |
| **V6** | ✅ | ❌ | ❌ | 15 | **Trust Claude, minimal overhead** |

### Recommendations

**Start here:** V2 or V6
- V2 for balanced approach with context
- V6 for maximum efficiency

**If V2/V6 insufficient:**
- Low coverage (<60%)? Try V3 (coverage-guided)
- High coverage but buggy? Try V4 (mutation-guided)
- Want comprehensive? Try V5 (both tools)

**When NOT to use V5:**
- Small repos (<1000 LOC) - overkill
- Time-constrained - slower
- Token budget limited - most expensive

---

## Variant Details

### V1: Baseline (Control)
```
✗ No pre-execution
✗ No tool guidance
✓ Simple 4-objective prompt
```

**Purpose:** Control group to match original "base" performance
**Expected:** 77.5% coverage, ~100% pass rate, ~2.9M tokens (schedule)

---

### V2: Baseline + Context ⭐ RECOMMENDED
```
✓ Pre-execution orientation
✗ No tool guidance
✓ Clear objectives
```

**Key features:**
- Language, structure, test files, size detected automatically
- No time wasted on repository discovery
- Claude gets oriented immediately

**Hypothesis:** 15-20% token reduction vs V1, same coverage
**Best for:** Default choice, most repos

---

### V3: Context + Coverage
```
✓ Pre-execution orientation
✓ Coverage tool instructions
✗ No mutation testing
```

**Key features:**
- Guides usage of coverage.py, nyc, jacoco
- Focus on uncovered lines and branches
- Prioritizes gaps systematically

**Hypothesis:** 5-10% coverage improvement vs V2
**Best for:** Repos with spotty coverage, systematic gap-filling

---

### V4: Context + Mutations
```
✓ Pre-execution orientation
✗ No coverage tool
✓ Mutation testing instructions
```

**Key features:**
- Guides mutmut, Stryker, PITest usage
- Focuses on test quality (killing mutants)
- Targets boundary conditions and edge cases

**Hypothesis:** Higher pass rates, better test quality vs V3
**Best for:** Repos with decent coverage but weak tests

---

### V5: Context + Both Tools
```
✓ Pre-execution orientation
✓ Coverage tool instructions
✓ Mutation testing instructions
```

**Key features:**
- Two-phase approach: coverage first, then mutations
- Comprehensive but complex
- Most prescriptive guidance

**Hypothesis:** Diminishing returns - 5% improvement, 30% more tokens
**Best for:** Critical codebases, comprehensive refinement

---

### V6: Minimal ⭐ MAXIMUM EFFICIENCY
```
✓ Pre-execution orientation
✗ No tool guidance
✓ Ultra-concise directive (3 sentences)
```

**Key features:**
- Trusts Claude's inherent testing knowledge
- Minimal overhead (15 lines total)
- Context + simple goal

**Hypothesis:** 90%+ of V2 performance, 50% fewer tokens
**Best for:** Experienced Claude users, token-constrained environments

---

## Expected Performance

Based on original experiment analysis:

### Baseline (V1):
- Schedule: 88% coverage, 100% pass, 2.94M tokens
- Mistune: 79% coverage, 94.6% pass, 5.95M tokens
- Click: 64% coverage, 100% pass, 2.37M tokens

### Predicted Winners:

**V2 (Baseline + Context):**
- Same coverage as V1 (~77.5% avg)
- 15-20% fewer tokens (~2.5M vs 2.9M on schedule)
- Maintained high pass rates

**V6 (Minimal):**
- 90-95% of V1 coverage (~70-75%)
- 40-50% fewer tokens (~1.5M on schedule)
- Trade slight coverage for major efficiency

**V3 (Coverage) or V4 (Mutations):**
- Potential 5-10% coverage boost (~82-85%)
- 10-15% more tokens than V2
- Value depends on specific repo needs

---

## Testing Protocol

### Phase 1: Quick Validation (1-2 hours)
Test V2 and V6 on schedule (smallest repo):
- Does V2 match V1 performance with fewer tokens?
- Does V6 achieve acceptable coverage efficiently?

### Phase 2: Full Comparison (4-6 hours)
If Phase 1 promising, test all variants on all 3 repos:
- Run each variant on schedule, mistune, click
- Use Sonnet-4-5 for consistency
- Compare to original baseline results

### Phase 3: Confirmation (Optional)
Test best 2-3 variants on new repos:
- Validate generalization beyond test set
- Test both Sonnet and Opus models

---

## Evaluation Metrics

### Primary (from original):
1. **Coverage %** - Final line coverage
2. **Pass Rate %** - Tests passing / total tests
3. **Token Usage** - Total tokens consumed
4. **Tests Added** - Count of new test functions

### Efficiency Metrics (new):
5. **Coverage/Token** - Coverage points per 1M tokens
6. **Quality Score** - (Coverage × Pass Rate) / 100
7. **Efficiency Score** - Quality / (Tokens / 1M)

### Success Criteria:
- **Minimum:** 75% coverage, 95% pass rate
- **Target:** Match baseline (77.5%, ~100%)
- **Stretch:** Exceed baseline with <70% tokens

---

## Universal Context Script

The `universal-context.sh` script provides the pre-execution commands used in V2-V6:
- Language detection (Python, JS, Java, C++, Go, Rust, etc.)
- Repository structure (tree or find)
- Test file location
- Code/test ratio
- Framework detection
- Initial coverage (if tools available)

**Usage in variants:** Embedded as `!` pre-execution blocks in YAML frontmatter

---

## Research Questions Answered

This experimental design systematically tests:

1. **Does pre-execution context help?**
   - Compare V1 (no context) vs V2 (context)
   - **Hypothesis:** Yes, reduces discovery overhead

2. **Do coverage tools add value?**
   - Compare V2 (no tools) vs V3 (coverage)
   - **Hypothesis:** Yes, for systematic gap-filling

3. **Do mutation tools add value?**
   - Compare V2 (no tools) vs V4 (mutations)
   - **Hypothesis:** Yes, for test quality

4. **Do combined tools help or hurt?**
   - Compare V3/V4 (single tools) vs V5 (both)
   - **Hypothesis:** Diminishing returns

5. **Can minimal prompts match performance?**
   - Compare V2 (full prompt) vs V6 (minimal)
   - **Hypothesis:** Yes, Claude knows how to test

---

## File Organization

```
improved-prompts/
├── README.md                    # This file
├── TAXONOMY.md                  # Detailed experimental design
├── universal-context.sh         # Orientation script
├── v1-baseline.md              # Control (replicate original base)
├── v2-baseline-context.md      # Recommended default
├── v3-context-coverage.md      # Coverage-guided
├── v4-context-mutations.md     # Mutation-guided
├── v5-context-both.md          # Combined tools
└── v6-minimal.md               # Maximum efficiency
```

---

## Contributing

If you test these variants, please share:
1. Repository size and language
2. Variant used
3. Results (coverage, pass rate, tokens)
4. Time to completion

This helps refine the recommendations for when each variant works best.

---

## Citation

Based on analysis of test suite refinement experiment comparing "base" vs "refine" strategies:
- Base (simple prompt): 77.5% coverage, 29.3M tokens
- Refine (complex 860-line workflow): 74.7% coverage, 35.8M tokens

**Key insight:** Simpler prompts with pre-execution context outperform complex workflows.

See `../ANALYSIS.md` for full experiment analysis.
