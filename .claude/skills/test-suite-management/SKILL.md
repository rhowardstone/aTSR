---
name: test-suite-management
description: Use when asked to improve, refine, or work on tests - automatically determines if test creation or refinement is needed, then orchestrates the appropriate workflow using coverage analysis, mutation testing, and property-based testing tools
---

# Test Suite Management

## Overview

Automatically determine the right test workflow: create tests from scratch or refine existing ones.

**Core principle:** Assess first, then act systematically.

## When to Use

**Always use when:**
- User asks to "improve tests", "refine tests", or "work on test suite"
- Requested to add test coverage
- Asked to make tests more robust
- Told to ensure code is well-tested

**Detection triggers:**
- `/refine-tests` command
- "Can you add tests?"
- "The tests aren't comprehensive enough"
- "We need better test coverage"

## When NOT to Use

- User explicitly requests TDD for NEW feature (use obra's test-driven-development skill)
- Writing a specific single test (just write it)
- Debugging a failing test (use systematic-debugging)

## The Decision Tree

```
1. Run atsr-size to assess codebase
2. Run atsr-detect to identify language/framework
3. Check for existing tests

IF no tests exist:
    → Use test-creation skill

ELSE IF tests exist:
    → Use test-refinement skill
```

## Quick Start

### Step 1: Assess the Codebase

```bash
# Add tools to PATH
export PATH="/home/user/aTSR/.claude/lib/atsr-tools:$PATH"

# Size assessment
atsr-size .

# Framework detection
atsr-detect .
```

**Interpret output:**
- `has_tests: false` → Need test creation
- `has_tests: true` → Need test refinement
- `approach: "direct-fix"` → < 100 LOC, just read and fix
- `approach: "full-workflow"` → Use complete toolchain

### Step 2: Route to Appropriate Skill

**No tests found:**
```
Use the test-creation skill to generate initial test suite
```

**Tests exist:**
```
Use the test-refinement skill to improve existing tests
```

**Tiny codebase (< 100 LOC):**
Skip skills - just read code and write missing tests directly.

## Tool Reference

| Tool | Purpose | When to Run |
|------|---------|-------------|
| `atsr-size` | Assess LOC, test ratio | Always first |
| `atsr-detect` | Find language/framework | Always second |

Both tools output JSON - read and use to make routing decision.

## Common Workflow

### Scenario: User Says "Improve our tests"

1. **Assess**:
```bash
SIZE=$(atsr-size .)
LANG=$(atsr-detect .)
```

2. **Check results**:
```bash
echo $SIZE | jq '.has_tests'
# false → Use test-creation
# true → Use test-refinement
```

3. **Route accordingly** - invoke the appropriate skill

### Scenario: Codebase < 100 LOC

Don't invoke tools. Just:
1. Read all code files
2. Read all test files (if any)
3. Identify missing tests (boundaries, errors, edge cases)
4. Write them directly
5. Done

## Red Flags

- Running full refinement on 50-line codebase (overkill)
- Not checking for tests before creating duplicates
- Using mutation testing when no tests exist
- Skipping size assessment (always assess first!)

## Integration with Other Skills

- **Before this:** Nothing - this is the entry point
- **After this → test-creation:** When no tests exist
- **After this → test-refinement:** When tests exist and need improvement
- **Instead of this → TDD:** When writing new feature code

## Success Criteria

- Correctly identified whether creation or refinement needed
- Invoked appropriate downstream skill
- Did not waste time on wrong approach

## The Bottom Line

**This skill is the router.** It doesn't do the work - it figures out WHAT work needs doing, then delegates to the specialized skill.

Assessment → Decision → Delegation.
