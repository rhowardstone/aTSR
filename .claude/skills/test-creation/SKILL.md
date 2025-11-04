---
name: test-creation
description: Use when codebase has no tests or very few tests (< 20% coverage) - analyzes source code to automatically generate comprehensive initial test suite with basic functionality, boundary values, and error condition tests
---

# Test Creation

## Overview

Generate a comprehensive initial test suite from scratch by analyzing source code.

**Core principle:** Automate the tedious baseline, focus human effort on quality.

## When to Use

**Use when:**
- No test files exist
- Test coverage < 20%
- User says "we need to add tests"
- Starting fresh with test automation

**Symptoms:**
- `atsr-size` shows `has_tests: false`
- Empty `tests/` directory
- No pytest/jest/junit files found

## When NOT to Use

- Tests already exist with >20% coverage (use test-refinement instead)
- Writing tests for new feature (use TDD instead)
- Codebase < 100 LOC (just write tests directly, faster than tooling)

## The Workflow

### Phase 1: Analyze Code Structure

```bash
# Add tools to PATH if not already
export PATH="/home/user/aTSR/.claude/lib/atsr-tools:$PATH"

# Analyze all source files
atsr-analyze-code . > /tmp/analysis.json
```

**Output interpretation:**
- Lists all functions and methods
- Provides suggested test names
- Identifies async functions
- Groups by file

### Phase 2: Generate Test Templates

```bash
atsr-generate-tests /tmp/analysis.json --output-dir tests/
```

**What this does:**
- Creates one test file per source file
- Generates basic test stubs
- Includes TODO comments for edge cases
- Sets up proper imports and structure

### Phase 3: Review and Customize

Generated tests are TEMPLATES, not final:

**Good generated test:**
```python
def test_calculate_total():
    """Test calculate_total with basic input"""
    # TODO: Add test implementation
    result = calculate_total(None)  # TODO: provide items
    assert result is not None  # Replace with actual assertion
```

**Your job:**
1. Replace `None` with real test data
2. Replace generic assertions with specific ones
3. Add the TODO edge cases:
   - Boundary values (0, -1, empty, None)
   - Error conditions (exceptions, invalid input)
   - Special cases specific to function

### Phase 4: Run and Fix

```bash
# Run generated tests
pytest tests/

# Fix any import errors, syntax issues
# Ensure all tests pass
```

### Phase 5: Handoff to Refinement

Once basic tests exist and pass:

```
Use test-refinement skill to add coverage and mutations
```

## Tool Reference

| Tool | Input | Output | Purpose |
|------|-------|--------|---------|
| `atsr-analyze-code` | Source directory | JSON with functions | Find what needs tests |
| `atsr-generate-tests` | Analysis JSON | Test files | Create test templates |

## Expert Patterns

### For Every Function, Generate:

1. **Basic test** - Happy path with valid input
2. **Boundary test stub** - TODO for 0, -1, empty, null
3. **Error test stub** - TODO for exceptions

### Python Example:

```python
# Function to test
def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

# Generated tests
def test_divide():
    """Test divide with basic input"""
    result = divide(10, 2)
    assert result == 5

def test_divide_boundaries():
    """Test divide with boundary values"""
    # TODO: Test with 0, negative numbers
    pass

def test_divide_errors():
    """Test divide error handling"""
    with pytest.raises(ValueError):
        divide(10, 0)
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Treating generated tests as final | They're templates - customize them! |
| Not running tests after generation | Always verify they work |
| Skipping TODO items | Those are the important edge cases! |
| Using on existing test suite | Use test-refinement instead |

## Success Metrics

**After test creation, you should have:**
- Test file for every source file
- At least 1 test per function
- All tests passing
- Clear TODOs for missing edge cases

**Typical results:**
- 100-line module → 10-15 basic tests
- 40-60% initial coverage
- Foundation for refinement

## The Bottom Line

**Test creation is the jumpstart.** It gets you from zero to baseline quickly. The generated tests aren't perfect - they're a structured starting point.

Analyze → Generate → Customize → Verify → Refine.
