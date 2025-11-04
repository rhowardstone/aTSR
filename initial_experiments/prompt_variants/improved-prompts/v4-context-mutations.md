---
description: Test suite refinement (V4 Context + Mutation Testing)
argument-hint: [auto]
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep
model: claude-sonnet-4-5-20250929
---

# Test Suite Improvement Task

## Repository Context

**Language Profile:**
!`find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" -o -name "*.go" -o -name "*.rs" \) ! -path "*/node_modules/*" ! -path "*/.venv/*" ! -path "*/venv/*" ! -path "*/__pycache__/*" ! -path "*/.git/*" ! -path "*/target/*" ! -path "*/build/*" -exec basename {} \; 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -5`

**Structure:**
!`tree -L 2 -I 'node_modules|__pycache__|.venv|venv|.git|target|build' --dirsfirst 2>/dev/null | head -30 || find . -maxdepth 2 -type d ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/.venv/*" | sort | head -20`

**Test Files:**
!`find . -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" -o -name "*.test.ts" -o -name "*Test.java" -o -name "*_test.go" \) ! -path "*/__pycache__/*" ! -path "*/node_modules/*" 2>/dev/null | head -15`

**Size:**
!`echo "Code files: $(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" \) ! -path "*/test*" ! -path "*/__pycache__/*" ! -path "*/node_modules/*" ! -path "*/.venv/*" 2>/dev/null | wc -l)" && echo "Test files: $(find . -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" \) 2>/dev/null | wc -l)"`

---

## Your Task

Improve test quality using mutation testing to find weak tests.

## Mutation-First Approach:

### 1. Run Quick Mutation Sample
Test your tests by introducing bugs:
- **Python:** `mutmut run --simple-output` (install: `pip install mutmut`)
- **JavaScript:** `npx stryker run` (install: `npm i -D @stryker-mutator/core`)
- **Java:** `mvn org.pitest:pitest-maven:mutationCoverage`

Time-box to 5-10 minutes or first 50 mutants.

### 2. Identify Weak Tests
Mutations that **survived** = your tests didn't catch them. Common survivors:
- **Boundary changes:** `>` → `>=` (missing exact boundary tests)
- **Return value changes:** `return x` → `return None` (missing null checks)
- **Operator changes:** `+` → `-` (insufficient assertions)
- **Boolean flips:** `if x:` → `if not x:` (missing both branches)

### 3. Write Tests to Kill Mutants
For each survived mutant, write a test that would catch it:
```python
# If mutant: changed >= to >
def test_boundary_exact_value():
    assert function(10) != function(9)  # Would catch the mutation

# If mutant: changed return x to return None
def test_return_not_none():
    result = function(valid_input)
    assert result is not None
```

### 4. Verify Improvement
Re-run mutations on improved tests. Aim for:
- 70%+ mutation score (killed / total)
- Focus on critical code paths
- 100% pass rate

## Expert Patterns to Test:
- **Boundaries:** Test exact points where logic changes (0, -1, max, min)
- **Error paths:** Test that exceptions ARE raised when they should be
- **Edge cases:** Empty lists, single elements, duplicates
- **Return values:** Non-null, correct types, expected ranges

Start by running a quick mutation sample, then target survivors.
