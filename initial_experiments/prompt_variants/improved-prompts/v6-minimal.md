---
description: Test suite refinement (V6 Minimal Directive)
argument-hint: [auto]
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep
model: claude-sonnet-4-5-20250929
---

## Repository Context

**Language:** !`find . -type f -name "*.py" -o -name "*.js" -o -name "*.java" -o -name "*.go" ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/__pycache__/*" | head -1 | sed 's/.*\.//'`

**Structure:** !`tree -L 2 -I 'node_modules|__pycache__|.venv|.git' --dirsfirst 2>/dev/null | head -20 || ls -d */`

**Tests:** !`find . -name "test_*.py" -o -name "*.test.js" -o -name "*Test.java" 2>/dev/null | wc -l` existing test files

---

## Task

Improve test coverage to 80%+.

Measure coverage, identify gaps, write targeted tests for boundaries/errors/edge-cases.

Verify: 80%+ coverage, 100% pass rate.
