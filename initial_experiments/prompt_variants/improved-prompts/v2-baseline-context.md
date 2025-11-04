---
description: Test suite refinement (V2 Baseline + Context)
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

Improve test coverage and quality to at least 80%.

## Approach:
1. Run existing tests and measure coverage
2. Identify gaps (files/functions <80% coverage)
3. Write targeted tests for:
   - Boundary conditions
   - Error handling
   - Edge cases
   - Critical paths

## Guidelines:
- Use the appropriate testing framework for this language
- Write clear, maintainable tests
- Include both positive and negative cases
- Add comments for complex test logic

Start by measuring coverage, then systematically fill gaps.
