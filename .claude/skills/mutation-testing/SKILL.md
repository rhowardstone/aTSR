---
name: mutation-testing
description: Use when coverage is good (>60%) but need to verify test quality - introduces bugs into code to check if tests catch them, identifies weak assertions and missing edge case tests
---

# Mutation Testing

## Overview

Introduce bugs. See if tests catch them. Improve tests that don't.

**Core principle:** If a test doesn't fail when code breaks, the test is worthless.

## When to Use

- Coverage > 60% (lower is waste of time)
- Tests exist but feel weak
- Need to verify test quality
- Called by test-refinement skill

## When NOT to Use

- No tests or low coverage (fix that first)
- Codebase < 100 LOC (overkill)
- Time-constrained (mutations are slow)

## Quick Reference

```bash
# Run mutations (time-limited)
atsr-mutate --timeout 600

# Analyze survivors
atsr-survivors .test-refinement/mutations/results.txt
```

## Understanding Results

**Killed mutant:** ✅ Test caught the bug (good!)
**Survived mutant:** ❌ Bug went undetected (bad!)

**Goal:** >70% mutation score (killed / total)

## Common Survivors

| Mutation Type | What It Means | Fix |
|---------------|---------------|-----|
| `>=` → `>` survived | Test doesn't check exact boundary | Add `assert func(10) != func(9)` |
| `return None` survived | Test doesn't check return value | Add `assert result is not None` |
| `and` → `or` survived | Test doesn't verify logic | Add test for both conditions |

## Fixing Survivors

For each survived mutant:

1. **Understand the mutation** - what changed?
2. **Ask: Why didn't tests catch it?**
   - Missing assertion?
   - Not testing boundary?
   - Not checking specific value?
3. **Write targeted test** that would kill it
4. **Verify** - re-run mutation on that function

## Example

**Survived mutant:**
```python
# Changed: if count >= 5  →  if count > 5
```

**Why it survived:**
Existing test: `assert process(10) == "many"`

Test passes with both `>= 5` and `> 5` because 10 satisfies both.

**Fix:**
```python
def test_process_boundary():
    """Test exact boundary at 5"""
    assert process(5) == "many"  # Kills the mutant
    assert process(4) != "many"
```

## Tool Usage

`atsr-mutate` handles:
- Python: mutmut
- JavaScript: stryker
- Automatically time-boxes (10 min default)

Output location: `.test-refinement/mutations/`

## Red Flags

- Mutation score < 50% (tests are very weak)
- Running on code with < 60% coverage
- Trying to kill all mutants (diminishing returns after 80%)

## The Bottom Line

Mutations test your tests. Survivors reveal weak spots.

Run → Analyze survivors → Write killer tests → Verify.
