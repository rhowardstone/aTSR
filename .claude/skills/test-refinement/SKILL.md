---
name: test-refinement
description: Use when tests exist but need improvement (coverage gaps, weak assertions, missing edge cases) - systematically improves test quality using coverage analysis to find gaps and mutation testing to verify test strength
---

# Test Refinement

## Overview

Systematically improve existing test suites using scientific methodology: coverage analysis finds gaps, mutation testing proves quality.

**Core principle:** Measure, challenge, improve, verify.

## When to Use

**Use when:**
- Tests exist with < 80% coverage
- Mutation testing shows weak tests
- User asks to "improve" or "strengthen" tests
- Tests pass but feel incomplete

**Symptoms:**
- `atsr-size` shows `has_tests: true`
- Coverage exists but has gaps
- Tests don't catch real bugs
- Weak or generic assertions

## When NOT to Use

- No tests exist (use test-creation first)
- Coverage already >90% with strong tests
- Codebase < 100 LOC (read and fix directly)

## The Workflow

### Phase 1: Baseline Coverage Analysis

```bash
export PATH="/home/user/aTSR/.claude/lib/atsr-tools:$PATH"

# Run coverage
atsr-coverage

# Analyze gaps
atsr-gaps .test-refinement/coverage/coverage.json > /tmp/gaps.json
```

**Decision gate:**
- Total coverage < 60%? Focus on basic test writing first
- Coverage 60-80%? Proceed with targeted refinement
- Coverage > 80%? Move to mutation testing

### Phase 2: Fill Critical Gaps

Use `coverage-analysis` skill to systematically add tests for:
- Uncovered functions (0% coverage)
- Uncovered branches (if/else paths)
- Error paths (exception handling)

**Priority order:**
1. Core business logic (highest risk)
2. Utility functions (high usage)
3. Edge case handling
4. Nice-to-have paths

### Phase 3: Mutation Testing

**Only run if coverage > 60%**

```bash
# Run mutations (time-boxed)
atsr-mutate --timeout 600

# Analyze survivors
atsr-survivors .test-refinement/mutations/results.txt
```

Use `mutation-testing` skill to interpret results and add killer tests.

### Phase 4: Property-Based Testing

For algorithmic code (sorting, parsing, transforms):

```bash
# Get recommendations
atsr-recommend /tmp/analysis.json
```

Use `property-based-testing` skill to add hypothesis/fast-check tests.

## Skill Integration

This skill orchestrates other skills:

1. **coverage-analysis** - Find and fix gaps
2. **mutation-testing** - Verify test quality
3. **property-based-testing** - Add algorithmic tests
4. **test-gap-analysis** - Prioritize what to fix

## Tool Reference

| Tool | When | Output |
|------|------|--------|
| `atsr-coverage` | Always first | Coverage data in JSON |
| `atsr-gaps` | After coverage | Prioritized gap list |
| `atsr-mutate` | If coverage > 60% | Mutation results |
| `atsr-survivors` | After mutations | Test recommendations |
| `atsr-recommend` | For property tests | Suggested property tests |

## Quick Decision Matrix

| Coverage | Mutation Score | Action |
|----------|---------------|--------|
| < 60% | N/A | Skip mutations, focus on gaps |
| 60-80% | < 70% | Coverage + targeted mutations |
| > 80% | < 70% | Focus on mutation killing |
| > 80% | > 70% | Add property tests, done! |

## Example Workflow

### Scenario: 65% coverage, unknown mutation score

```bash
# 1. Get baseline
atsr-coverage
atsr-gaps .test-refinement/coverage/coverage.json

# Output shows:
# - 3 files with < 50% coverage (HIGH PRIORITY)
# - 5 files with 50-80% coverage (MEDIUM)

# 2. Fix high-priority gaps
#    Read the 3 files, identify uncovered:
#    - Functions
#    - Branches
#    - Error paths
#    Write tests to cover them

# 3. Verify improvement
atsr-coverage  # Should see coverage increase

# 4. Run mutations (coverage now >70%)
atsr-mutate --timeout 300
atsr-survivors .test-refinement/mutations/results.txt

# Output shows:
# - 12 boundary condition survivors
# - 3 null check survivors

# 5. Add killer tests for survivors
#    Focus on exact boundary values
#    Add null/None checks
```

## Red Flags

- Running mutations before 60% coverage (waste of time)
- Not re-running coverage after adding tests (can't measure progress)
- Treating coverage as the goal (it's a map, not the destination)
- Adding tests without understanding what they test

## Success Criteria

**After refinement:**
- Coverage > 80% for critical code, >60% overall
- Mutation score > 70% for covered code
- Tests catch real bugs (not just execute code)
- Clear, focused assertions

## The Bottom Line

**Test refinement is systematic improvement.** Coverage shows WHERE to add tests. Mutations show IF tests are strong. Property tests show HOW to test algorithms.

Don't guess. Measure → Improve → Verify.
