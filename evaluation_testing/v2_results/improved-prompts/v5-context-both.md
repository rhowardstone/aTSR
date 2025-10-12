---
description: Test suite refinement (V5 Context + Coverage + Mutations)
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

Improve test coverage (80%+) and quality using both coverage and mutation testing.

## Two-Phase Approach:

### Phase 1: Coverage (Breadth)
Run coverage to find untested code:
- **Python:** `coverage run -m pytest && coverage report --skip-covered`
- **JavaScript:** `npm test -- --coverage`
- **Java:** `mvn test jacoco:report`

Write tests for <80% coverage areas:
- Focus on uncovered lines and branches
- Prioritize core logic and public APIs
- Include boundary conditions and error paths

### Phase 2: Mutations (Depth)
Run mutation testing to find weak tests:
- **Python:** `mutmut run --simple-output` (time-boxed: 5-10 min)
- **JavaScript:** `npx stryker run`
- **Java:** `mvn org.pitest:pitest-maven:mutationCoverage`

Strengthen tests for survived mutants:
- Boundary changes (`>` → `>=`) - Add exact boundary tests
- Return changes (`return x` → `return None`) - Add null checks
- Operator changes (`+` → `-`) - Strengthen assertions
- Boolean flips - Test both branches explicitly

### Verification:
Re-run both tools after improvements. Target:
- **Coverage:** 80%+ lines, 70%+ branches
- **Mutations:** 70%+ killed
- **Quality:** 100% pass rate

## Key Testing Patterns:
1. **Boundaries:** 0, -1, null, empty, max - where logic changes
2. **Errors:** Verify exceptions ARE raised when expected
3. **Edge cases:** Empty, single element, duplicates, extremes
4. **Assertions:** Test return values, side effects, state changes

Start with coverage to fill gaps, then use mutations to strengthen tests.
