#!/bin/bash
# Universal Repository Orientation Script
# Works across all languages and repo structures
# Designed to be copied into Claude Code slash command pre-execution blocks

# ============================================
# Language Detection (GitHub Linguist style)
# ============================================
echo "=== LANGUAGE PROFILE ==="
find . -type f \( \
    -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o \
    -name "*.java" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" -o \
    -name "*.go" -o -name "*.rs" -o -name "*.rb" -o -name "*.php" -o \
    -name "*.swift" -o -name "*.kt" -o -name "*.scala" -o -name "*.cs" -o \
    -name "*.r" -o -name "*.R" -o -name "*.m" -o -name "*.lean" -o \
    -name "*.hs" -o -name "*.ml" -o -name "*.ex" -o -name "*.exs" \
\) \
    ! -path "*/node_modules/*" ! -path "*/.venv/*" ! -path "*/venv/*" \
    ! -path "*/__pycache__/*" ! -path "*/.git/*" ! -path "*/target/*" \
    ! -path "*/build/*" ! -path "*/dist/*" \
    -exec basename {} \; 2>/dev/null | \
    sed 's/.*\.//' | sort | uniq -c | sort -rn | head -5

# ============================================
# Repository Structure (2-level tree)
# ============================================
echo ""
echo "=== REPO STRUCTURE ==="
if command -v tree &>/dev/null; then
    tree -L 2 -I 'node_modules|__pycache__|.venv|venv|.git|target|build|dist' --dirsfirst | head -40
else
    # Fallback if tree not available
    find . -maxdepth 2 -type d ! -path "*/node_modules/*" ! -path "*/.venv/*" ! -path "*/.git/*" | sort | head -25
fi

# ============================================
# Test File Detection
# ============================================
echo ""
echo "=== TEST FILES ==="
find . -type f \( \
    -name "test_*.py" -o -name "*_test.py" -o -name "test*.py" -o \
    -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.spec.ts" -o \
    -name "*Test.java" -o -name "*Tests.java" -o \
    -name "*_test.go" -o -name "*test.cpp" -o -name "*test.c" \
\) \
    ! -path "*/__pycache__/*" ! -path "*/node_modules/*" ! -path "*/.git/*" \
    2>/dev/null | head -20

# ============================================
# Code vs Test Ratio
# ============================================
echo ""
echo "=== SIZE ASSESSMENT ==="
CODE_COUNT=$(find . -type f \( \
    -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o \
    -name "*.cpp" -o -name "*.c" -o -name "*.go" -o -name "*.rs" \
\) \
    ! -path "*/test*" ! -path "*/__pycache__/*" ! -path "*/node_modules/*" \
    ! -path "*/.venv/*" ! -path "*/.git/*" 2>/dev/null | wc -l)

TEST_COUNT=$(find . -type f \( \
    -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" -o \
    -name "*Test.java" -o -name "*_test.go" \
\) 2>/dev/null | wc -l)

CODE_LINES=$(find . -type f \( \
    -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" \
\) \
    ! -path "*/test*" ! -path "*/__pycache__/*" ! -path "*/node_modules/*" \
    ! -path "*/.venv/*" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')

echo "Code files: $CODE_COUNT"
echo "Test files: $TEST_COUNT"
echo "Code lines: ${CODE_LINES:-unknown}"
echo "Code/Test ratio: $(echo "scale=1; $CODE_COUNT / ($TEST_COUNT + 1)" | bc 2>/dev/null || echo "~$((CODE_COUNT / (TEST_COUNT + 1)))")"

# ============================================
# Test Framework Detection
# ============================================
echo ""
echo "=== TEST FRAMEWORK ==="
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || grep -q "pytest" requirements*.txt 2>/dev/null; then
    echo "Python: pytest detected"
elif [ -f "setup.py" ]; then
    echo "Python: unittest (default)"
fi

if [ -f "package.json" ]; then
    if grep -q "jest" package.json; then
        echo "JavaScript: Jest detected"
    elif grep -q "mocha" package.json; then
        echo "JavaScript: Mocha detected"
    fi
fi

if [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
    echo "Java: JUnit (standard)"
fi

if [ -f "go.mod" ]; then
    echo "Go: testing package (standard)"
fi

if [ -f "Cargo.toml" ]; then
    echo "Rust: cargo test (standard)"
fi

# ============================================
# Quick Coverage Check (if tools available)
# ============================================
echo ""
echo "=== INITIAL COVERAGE (if available) ==="

# Python coverage
if command -v coverage &>/dev/null && [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
    timeout 30 coverage run -m pytest 2>/dev/null && \
        INITIAL_COV=$(coverage report 2>/dev/null | grep TOTAL | awk '{print $4}')
    echo "Python coverage: ${INITIAL_COV:-unknown}"
fi

# JavaScript coverage
if [ -f "package.json" ] && grep -q "jest" package.json; then
    timeout 30 npm test -- --coverage --silent 2>/dev/null | grep "All files" | awk '{print $10}' || echo "JavaScript coverage: unknown"
fi

# If no coverage available
if [ -z "$INITIAL_COV" ]; then
    echo "No coverage data available (tools not installed or tests not configured)"
fi

echo ""
echo "=== ORIENTATION COMPLETE ==="
