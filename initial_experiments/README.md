# Initial Experiments

This directory contains the original research and prompt design iterations that led to the current skill-based system.

## Background

We initially explored using a **monolithic prompt** approach for test suite refinement. Through systematic experimentation, we discovered that **simpler, modular approaches outperform complex workflows**.

---

## Contents

### 1. `monolithic_prompt.md`

The original **860-line prompt** with inline bash and Python scripts.

**Key characteristics:**
- Comprehensive 6-phase workflow
- Inline scripts for coverage, mutations, test generation
- Decision matrices and heuristics
- Size assessment (< 100 LOC → direct fix, > 5000 LOC → full workflow)

**Problems discovered:**
- ❌ Agents copied inline scripts wastefully (high token usage)
- ❌ Complex decision trees caused wandering
- ❌ No clear separation between "what to do" and "how to do it"
- ❌ Worse performance than baseline (74.7% vs 77.5% coverage)

### 2. `prompt_variants/`

Six systematically designed prompt iterations testing different hypotheses:

| Variant | Pre-Exec Context | Coverage Tools | Mutation Tools | Lines |
|---------|------------------|----------------|----------------|-------|
| **v1-baseline.md** | ❌ | ❌ | ❌ | 30 |
| **v2-baseline-context.md** | ✅ | ❌ | ❌ | 40 |
| **v3-context-coverage.md** | ✅ | ✅ | ❌ | 60 |
| **v4-context-mutations.md** | ✅ | ❌ | ✅ | 60 |
| **v5-context-both.md** | ✅ | ✅ | ✅ | 80 |
| **v6-minimal.md** | ✅ | ❌ | ❌ | 15 |

**Research questions:**
1. Does pre-execution context reduce token usage? (Compare v1 vs v2)
2. Do coverage tools add value? (Compare v2 vs v3)
3. Do mutation tools add value? (Compare v2 vs v4)
4. Do combined tools help or hurt? (Compare v3/v4 vs v5)
5. Can minimal prompts match performance? (Compare v2 vs v6)

**Key findings:**
- ✅ Pre-execution context reduces token usage (v2 beat v1)
- ✅ Simple prompts can outperform complex workflows
- ❌ Complex tool guidance can backfire (diminishing returns)

See `prompt_variants/README.md` and `prompt_variants/TAXONOMY.md` for full analysis.

---

## Experimental Results

### Benchmark: Baseline vs Monolithic

| Approach | Avg Coverage | Avg Pass Rate | Avg Tokens |
|----------|-------------|---------------|------------|
| **Base** (simple prompt) | **77.5%** | **100%** | 29.3M |
| **Refine** (monolithic) | 74.7% | 98.6% | 35.8M ❌ |

**Lesson:** The complex 860-line workflow performed **worse** while using **more tokens**.

### Why Monolithic Failed

1. **Inline scripts**: Agents copied 100+ line bash/Python scripts verbatim
2. **Tool overhead**: Setting up extensive tooling took longer than writing tests
3. **Decision paralysis**: Too many paths → agents wandered
4. **No reusability**: Scripts were one-off, not shared across runs

---

## What We Learned → Skill-Based Design

From these experiments, we derived principles for the current system:

### ✅ Do This (Skills)
- **Modular**: One focused skill per concern (< 500 words)
- **Separation**: Skills teach WHEN/HOW, tools do WHAT
- **Deterministic tools**: CLI scripts agents invoke (not copy)
- **Clear routing**: test-suite-management decides create vs refine
- **Token efficient**: No inline scripts, cross-reference other skills

### ❌ Don't Do This (Monolithic)
- Inline scripts (agents copy wastefully)
- Complex decision trees (agents wander)
- One massive prompt (hard to maintain)
- Tool instructions without tools (agents improvise poorly)

---

## Evolution Timeline

```
Oct 2024: Original monolithic prompt (860 lines)
    ↓
    Benchmark results: Worse than baseline
    ↓
Oct 2024: Prompt variant experiments (v1-v6)
    ↓
    Finding: Simpler prompts work better
    ↓
Nov 2024: Analyze obra/superpowers patterns
    ↓
    Adopt: Flat skills, thin commands, CLI tools
    ↓
Nov 2024: Build skill-based system
    ↓
    Result: .claude/skills/ + .claude/lib/atsr-tools/
```

---

## Reproducibility

All experiments are preserved here for:
- **Reproducibility**: Exact prompts used in benchmarks
- **Historical context**: Why we made design decisions
- **Future research**: Starting point for improvements

To reproduce the original experiments:
1. Use `monolithic_prompt.md` as `/refine-tests` command
2. Run on schedule/mistune/click repos
3. Compare with baseline (simple prompt)

---

## References

- Original benchmark results: `evaluation_testing/evaluation_20251001_085526/`
- Prompt variant analysis: `prompt_variants/README.md`
- Current skill system: `../.claude/skills/`

---

**Key Takeaway**: Simpler, modular approaches beat complex monoliths. The skill-based system embodies these lessons.
