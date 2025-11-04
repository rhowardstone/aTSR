---
name: test-gap-analysis
description: Use when you have coverage data and need to prioritize which gaps to fix first - analyzes coverage results to identify high-risk untested code and creates action plan ordered by criticality
---

# Test Gap Analysis

## Overview

Not all coverage gaps are equal. Fix critical ones first.

**Core principle:** Prioritize by risk, not by coverage percentage.

## When to Use

- Coverage analysis completed
- Multiple gaps identified
- Need to prioritize work
- Limited time/resources

## Prioritization Framework

### High Priority
- Core business logic (0% coverage)
- Functions that handle money/security
- Error paths in critical code
- Public APIs with no tests

### Medium Priority
- Utility functions (partial coverage)
- Branch coverage gaps
- Edge case handling
- Less critical paths

### Low Priority
- Logging code
- Simple getters/setters
- Unreachable code
- Nice-to-have paths

## Quick Analysis

```bash
# Get gaps
atsr-gaps .test-refinement/coverage/coverage.json

# Output shows files sorted by coverage (lowest first)
```

**Focus on:**
1. Files with < 50% coverage AND high complexity
2. Error handling with 0% coverage
3. Public functions with no tests

## The Decision Matrix

| Coverage | Complexity | Risk | Action |
|----------|-----------|------|--------|
| < 50% | High | 🔴 Critical | Fix immediately |
| < 50% | Low | 🟡 Medium | Fix after critical |
| 50-80% | High | 🟡 Medium | Target branches |
| > 80% | Any | 🟢 Low | Optional |

## Example Workflow

Given gaps output:
```json
{
  "gaps": [
    {"file": "payment.py", "coverage": 35%, "priority": "high"},
    {"file": "utils.py", "coverage": 45%, "priority": "medium"},
    {"file": "logging.py", "coverage": 60%, "priority": "low"}
  ]
}
```

**Action plan:**
1. Fix `payment.py` first (high priority, low coverage)
2. Then `utils.py` (medium priority)
3. Skip `logging.py` for now (low priority, decent coverage)

## For Each Gap

1. **Read the file** - understand what it does
2. **Assess criticality** - does it handle money/data/security?
3. **Check existing tests** - what's already covered?
4. **Identify missing:**
   - Uncovered functions
   - Untested branches
   - Error paths
5. **Write tests** in priority order

## The Bottom Line

Fix critical gaps before optimizing coverage percentage.

100% coverage of logging < 60% coverage of business logic.

Prioritize by risk, not by metrics.
