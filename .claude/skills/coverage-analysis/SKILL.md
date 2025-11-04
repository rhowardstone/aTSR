---
name: coverage-analysis
description: Use when you have test coverage data and need to identify which code is untested - runs coverage tools, parses results, and prioritizes gaps by risk level for systematic gap-filling
---

# Coverage Analysis

## Overview

Run coverage tools, find gaps, prioritize fixes.

**Core principle:** Coverage is a map showing where tests are missing.

## When to Use

- Called by test-refinement skill
- Need to identify untested code
- Want to measure test progress

## Quick Reference

```bash
# Run coverage
atsr-coverage

# Find gaps
atsr-gaps .test-refinement/coverage/coverage.json

# Output shows prioritized files with coverage < 80%
```

## Interpreting Results

**High priority (< 50% coverage):**
- Completely untested modules
- Critical business logic with gaps
- Error paths not exercised

**Medium priority (50-80% coverage):**
- Partially tested modules
- Missing edge cases
- Incomplete branch coverage

**Low priority (> 80% coverage):**
- Well-tested code
- Minor gap filling

## Adding Tests for Gaps

For each gap file:

1. **Read the source file** - understand what it does
2. **Read existing tests** - see what's already covered
3. **Identify uncovered:**
   - Functions with no tests
   - Branches not taken (if/else paths)
   - Error conditions not triggered
4. **Write tests** to cover them
5. **Re-run coverage** to verify improvement

## Common Patterns

**Uncovered error path:**
```python
# Source has:
if user is None:
    raise ValueError("User required")  # Not covered!

# Add test:
def test_validate_user_none():
    with pytest.raises(ValueError, match="User required"):
        validate_user(None)
```

**Uncovered branch:**
```python
# Source has:
if score >= 90:
    return "A"  # Covered
else:
    return "B"  # Not covered!

# Add test:
def test_grade_b():
    assert calculate_grade(85) == "B"
```

## Tool Usage

`atsr-coverage` runs the appropriate tool for your language:
- Python: coverage.py
- JavaScript: jest --coverage or nyc
- Java: jacoco

Output location: `.test-refinement/coverage/`

## The Bottom Line

Coverage finds the map. You fill the gaps.

Read code → Identify uncovered → Write tests → Verify.
