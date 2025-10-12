# Prompt Variant Taxonomy

**Research Question:** How can we achieve near-base performance (95%+) with significantly lower token cost (50% reduction)?

**Experimental Design:** Factorial testing to isolate the impact of each component.

---

## Variant Matrix

| Variant | Pre-Exec Context | Coverage Tool | Mutation Tool | Prompt Length | Hypothesis |
|---------|------------------|---------------|---------------|---------------|------------|
| **V1: Baseline** | ❌ No | ❌ No | ❌ No | ~30 lines | **Control** - Replicate original base performance |
| **V2: +Context** | ✅ Yes | ❌ No | ❌ No | ~40 lines | Context reduces discovery overhead → faster, cheaper |
| **V3: +Coverage** | ✅ Yes | ✅ Yes | ❌ No | ~60 lines | Coverage targeting improves test quality |
| **V4: +Mutations** | ✅ Yes | ❌ No | ✅ Yes | ~60 lines | Mutations improve test robustness (vs just coverage) |
| **V5: +Both** | ✅ Yes | ✅ Yes | ✅ Yes | ~80 lines | Combined tools provide complementary value |
| **V6: Minimal** | ✅ Yes | ❌ No | ❌ No | ~15 lines | Trust Claude's judgment → minimal overhead |

---

## Component Definitions

### 1. Pre-Execution Context (`!` blocks)

Universal orientation commands that run BEFORE the prompt:
- **Language detection** (Python, JS, Java, C++, Go, Rust, etc.)
- **Repo structure** (tree -L 2 or equivalent)
- **Test location** (find test files)
- **Initial coverage** (quick check if possible)
- **File counts** (size assessment)

**Benefits:**
- No token waste on discovery
- Immediate orientation
- Adaptive to any repo

### 2. Coverage Tool Guidance

Minimal instructions for using coverage.py, pytest-cov, nyc, or similar:
- Run coverage on existing tests
- Identify files/functions <80% coverage
- Target tests to those gaps

**NOT included:** Complex setup scripts, decision matrices, tool installation

### 3. Mutation Testing Guidance

Minimal instructions for using mutmut, Stryker, or PITest:
- Run quick mutation sample (time-boxed)
- Identify survived mutants
- Write tests to kill them

**NOT included:** Full mutation runs, complex analysis, elaborate reporting

---

## Testable Hypotheses

### H1: Context Reduces Token Waste
**Variants:** V1 (control) vs V2 (+context)
- **Prediction:** V2 uses 15-20% fewer tokens while maintaining coverage
- **Mechanism:** No time wasted on `pwd`, `ls`, `find` commands
- **Metric:** Token usage, time-to-first-test

### H2: Coverage Tool Improves Targeting
**Variants:** V2 (+context) vs V3 (+coverage)
- **Prediction:** V3 achieves 5-10% higher coverage with same token budget
- **Mechanism:** Direct gap identification vs guessing
- **Metric:** Coverage %, tests-per-coverage-point

### H3: Mutations Improve Quality Over Coverage
**Variants:** V3 (+coverage) vs V4 (+mutations)
- **Prediction:** V4 has higher pass rates, lower test counts, similar coverage
- **Mechanism:** Quality tests that catch real bugs vs just line coverage
- **Metric:** Pass rate, tests added, mutation score

### H4: Combined Tools Have Diminishing Returns
**Variants:** V3, V4 vs V5 (+both)
- **Prediction:** V5 adds <5% value vs individual tools, costs 30% more tokens
- **Mechanism:** Redundant information, complexity overhead
- **Metric:** Coverage delta, token cost, pass rate

### H5: Minimal Prompt Matches Performance
**Variants:** V2 (+context) vs V6 (minimal)
- **Prediction:** V6 achieves 90%+ of V2 performance with 50% fewer tokens
- **Mechanism:** Claude inherently knows how to test, don't over-instruct
- **Metric:** Coverage/token ratio (efficiency)

---

## Evaluation Metrics

### Primary Metrics (from original experiment):
1. **Coverage %** - Final line coverage
2. **Pass Rate %** - Percentage of tests passing
3. **Token Usage** - Total tokens consumed
4. **Tests Added** - Number of new test functions

### Derived Efficiency Metrics:
5. **Coverage/Token** - Coverage points per 1M tokens
6. **Quality Score** - (Coverage × Pass Rate) / 100
7. **Efficiency Score** - Quality Score / (Tokens / 1M)

### Success Criteria:
- **Minimum viable:** 75% coverage, 95% pass rate
- **Target:** Match base (77.5% coverage, ~100% pass rate)
- **Stretch:** Exceed base while using <70% tokens

---

## Implementation Notes

### Universal Pre-Execution Block

All variants V2-V6 share this orientation script:

```bash
# Language detection (covers all major languages)
!`find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" -o -name "*.go" -o -name "*.rs" -o -name "*.rb" -o -name "*.php" -o -name "*.swift" -o -name "*.kt" \) ! -path "*/node_modules/*" ! -path "*/.venv/*" ! -path "*/venv/*" ! -path "*/__pycache__/*" ! -path "*/.git/*" -exec basename {} \; | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -5`

# Repo structure (2 levels)
!`tree -L 2 -I 'node_modules|__pycache__|.venv|venv|.git' || find . -maxdepth 2 -type d | head -20`

# Test file locations
!`find . -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "test*.js" -o -name "*.test.js" -o -name "*Test.java" \) ! -path "*/__pycache__/*" ! -path "*/node_modules/*" | head -20`

# Code vs Test ratio
!`echo "Code files: $(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.java" \) ! -path "*/test*" ! -path "*/__pycache__/*" ! -path "*/node_modules/*" | wc -l)" && echo "Test files: $(find . -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" \) | wc -l)"`
```

**Rationale:** These commands work universally, fail gracefully, and provide exactly what any developer would check first.

### Prompt Length Targets

- **V1 (Baseline):** 30 lines - Match original base prompt
- **V2 (+Context):** 40 lines - Add context section
- **V3-V4 (Single Tool):** 60 lines - Add one tool guidance
- **V5 (+Both):** 80 lines - Add both tools
- **V6 (Minimal):** 15 lines - Ultra-concise directive

**Why length matters:** Token cost correlates with prompt length (cache creation). Shorter = cheaper.

---

## Testing Protocol

### Phase 1: Validation (Same repos as original)
Test all 6 variants on:
- schedule (small, ~1K LOC)
- mistune (medium, ~5K LOC)
- click (large, ~11K LOC)

**Models:** Sonnet-4-5 only (for speed)
**Outcome:** Identify best 2-3 variants

### Phase 2: Confirmation (Best variants only)
Test top performers on:
- Original 3 repos
- 2-3 new repos

**Models:** Both Sonnet-4-5 and Opus-4-1
**Outcome:** Validate generalization

---

## Expected Findings

### Predicted Winner: **V2 (+Context)** or **V6 (Minimal)**

**Why V2:**
- Context eliminates discovery overhead
- Simple prompt lets Claude use natural testing knowledge
- No tool complexity to distract

**Why V6:**
- Ultimate efficiency
- Trust Claude's inherent capabilities
- Minimal token overhead

**Why NOT V5 (+Both):**
- Based on original experiment, refine's complexity hurt performance
- Diminishing returns from multiple tools
- Token cost outweighs benefits

---

## Contribution to Field

This experiment systematically answers:
1. **When does pre-execution context help?** (Always? Never? Depends on repo size?)
2. **When do coverage tools add value?** (Small repos? Large? Never?)
3. **When do mutation tools add value?** (After high coverage? Instead of coverage?)
4. **What's the ROI of prompt complexity?** (Linear? Diminishing? Negative?)

**Actionable outcomes:**
- Guidelines for when to use each tool
- Efficiency benchmarks (coverage/token ratios)
- Best practices for test suite refinement prompts
- Evidence-based recommendations vs folk wisdom
