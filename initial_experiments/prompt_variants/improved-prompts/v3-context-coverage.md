---
description: Test suite refinement (V3 Context + Coverage Tool)
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

Improve test coverage to at least 80% using coverage-guided testing.

## Coverage-First Approach:

### 1. Measure Baseline
Run coverage on existing tests:
- **Python:** `coverage run -m pytest && coverage report --skip-covered`
- **JavaScript:** `npm test -- --coverage` or `npx nyc npm test`
- **Java:** `mvn test jacoco:report`

### 2. Identify Gaps
Look for files/functions with <80% coverage. Prioritize:
- Core business logic
- Public APIs
- Error handling paths
- Frequently used utilities

### 3. Write Targeted Tests
For each gap, write tests covering:
- **Uncovered lines** - What branches aren't executed?
- **Boundary conditions** - 0, -1, null, empty, max values
- **Error paths** - What exceptions should be raised?
- **Edge cases** - First, last, single element, empty collections

### 4. Verify Improvement
Re-run coverage after each batch of tests. Aim for:
- 80%+ line coverage
- 70%+ branch coverage
- 100% pass rate

## Guidelines:
- Let coverage guide you, but don't chase 100% blindly
- Some code (defensive checks, logging) doesn't need tests
- Focus on quality tests that catch real bugs
- Clear test names: `test_function_raises_error_on_negative_input()`

Start by running coverage, then systematically target gaps.
