# aTSR - Agentic Test Suite Refinement

**Project Memory and Architecture Documentation**

Last updated: 2025-11-05

---

## Project Overview

aTSR is a comprehensive test automation system for Claude Code that provides **end-to-end test lifecycle management**: from zero tests to comprehensive, high-quality test suites.

### Core Innovation

We combine **automated test creation** with **systematic test refinement** using scientific methodologies (coverage analysis, mutation testing, property-based testing).

---

## Competitive Analysis: aTSR vs obra/superpowers

### What obra/superpowers Provides

**Testing Skills:**
- ✅ `test-driven-development` - RED-GREEN-REFACTOR cycle, manual TDD
- ✅ `testing-anti-patterns` - Avoid testing mocks, test-only methods
- ✅ `condition-based-waiting` - Async test patterns
- ❌ NO test suite refinement
- ❌ NO coverage analysis automation
- ❌ NO mutation testing workflow
- ❌ NO property-based testing patterns
- ❌ NO automated test generation

**Architecture Patterns We Follow:**
- Flat skill namespace: `skills/skill-name/SKILL.md`
- YAML frontmatter: `name` and `description` only (max 1024 chars)
- Description format: "Use when [triggers] - [what it does]" (third person)
- Thin commands: 1-line wrappers that invoke skills
- Skills teach WHEN and HOW, tools do WHAT
- Test skills with subagents before deployment

### Our Complete Value Proposition

| Scenario | obra (TDD) | Baseline | aTSR (Us) |
|----------|-----------|----------|-----------|
| **No tests** | Manual TDD | Agent guesses | **Automated analysis → generate test suite** |
| **Some tests** | Manual TDD for new | Agent adds a few | **Systematic refinement (coverage + mutations)** |
| **Good tests** | Manual TDD for changes | "Looks good!" | **Quality verification + property tests** |

### Benchmark Positioning

We benchmark 3 test improvement strategies:
1. **refine (aTSR)**: Batch analysis with `/refine-tests` skill system
2. **base (Baseline)**: Simple prompt asking to improve tests
3. **incremental**: Step-by-step approach, one test at a time

**Note on obra TDD**: The test-driven-development skill is available via `src/setup_obra.sh`, but it's designed for **NEW feature development** (test-first), not test suite improvement. aTSR and obra TDD are **complementary**, not competing:
- obra TDD: Best for NEW features (test-first RED-GREEN-REFACTOR)
- aTSR: Best for EXISTING codebases (batch analysis, coverage-driven)

Metrics:
- Coverage % achieved
- Pass rate %
- Token usage
- Tests added (count)
- Time to completion

---

## Architecture

### Directory Structure

```
.claude/
├── skills/
│   ├── test-suite-management/          # Main orchestrator (decides create vs refine)
│   ├── test-creation/                  # Zero-to-tests automation
│   ├── test-refinement/                # Systematic improvement
│   ├── coverage-analysis/              # Coverage-guided gap finding
│   ├── mutation-testing/               # Quality verification
│   ├── property-based-testing/         # Algorithmic test generation
│   └── test-gap-analysis/              # Prioritize critical gaps
├── commands/
│   └── refine-tests.md                 # Thin wrapper: invoke test-suite-management
└── lib/
    └── atsr-tools/                     # Deterministic CLI utilities
        ├── atsr-size                   # Codebase assessment (LOC, complexity)
        ├── atsr-detect                 # Framework/language detection
        ├── atsr-analyze-code           # Find functions needing tests
        ├── atsr-generate-tests         # Generate initial test templates
        ├── atsr-coverage               # Universal coverage runner
        ├── atsr-gaps                   # Parse coverage, find gaps
        ├── atsr-mutate                 # Universal mutation runner
        ├── atsr-survivors              # Analyze survived mutants
        └── atsr-recommend              # Generate test recommendations
```

### Workflow Decision Tree

```
User: /refine-tests
    ↓
test-suite-management skill
    ↓
├─ NO TESTS? → test-creation skill
│              ├─ atsr-analyze-code (find functions)
│              ├─ atsr-generate-tests (create templates)
│              └─ Run tests, verify they pass
│              ↓
└─ TESTS EXIST? → test-refinement skill
               ├─ coverage-analysis skill
               │  ├─ atsr-coverage (run coverage)
               │  └─ atsr-gaps (find gaps)
               ├─ mutation-testing skill
               │  ├─ atsr-mutate (run mutations)
               │  └─ atsr-survivors (analyze)
               └─ property-based-testing skill
                  └─ atsr-recommend (suggest property tests)
```

---

## CLI Tools Design Principles

All tools in `lib/atsr-tools/` follow these conventions:

### Exit Codes
- `0` - Success
- `1` - Error (with stderr message)
- `2` - Usage error

### Output Format
- **JSON** for structured data (coverage, gaps, recommendations)
- **Plain text** for logs/progress
- **Stderr** for errors only

### Naming Convention
All tools prefixed with `atsr-` to avoid conflicts and provide discoverability.

### Tool Manifest

| Tool | Purpose | Input | Output |
|------|---------|-------|--------|
| `atsr-size` | Codebase sizing | Directory path | JSON: {loc, files, category} |
| `atsr-detect` | Framework detection | Directory path | JSON: {language, framework, test_runner} |
| `atsr-analyze-code` | Find functions | Source files | JSON: [functions needing tests] |
| `atsr-generate-tests` | Create tests | Function list | Test files generated |
| `atsr-coverage` | Run coverage | Test runner | JSON: coverage data |
| `atsr-gaps` | Parse gaps | Coverage JSON | JSON: prioritized gaps |
| `atsr-mutate` | Run mutations | Source files | JSON: mutation results |
| `atsr-survivors` | Analyze survivors | Mutation JSON | JSON: recommendations |
| `atsr-recommend` | Test suggestions | Code + coverage | JSON: test templates |

---

## Skill Design Following obra Patterns

### Frontmatter Requirements
```yaml
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions] - [what it does, third person]
---
```

### Content Structure
1. **Overview** - Core principle in 1-2 sentences
2. **When to Use** - Bullet list with symptoms/triggers
3. **When NOT to Use** - Anti-patterns
4. **Quick Reference** - Table or bullets
5. **Tool Usage** - How to invoke CLI tools and interpret output
6. **Common Mistakes** - What goes wrong + fixes

### Token Efficiency
- Keep skills < 500 words
- Move details to tool `--help`
- Use cross-references for related skills
- One excellent example beats many mediocre ones

---

## Multi-Language Support

### Supported Languages
- Python (pytest, unittest, coverage.py, mutmut)
- JavaScript/TypeScript (jest, mocha, nyc, stryker)
- Java (junit, jacoco, pitest)
- C/C++ (ctest, gcov, mull)

### Detection Strategy
`atsr-detect` checks for:
- **Python**: `setup.py`, `pyproject.toml`, `requirements.txt`, `pytest.ini`
- **JS/TS**: `package.json`, `tsconfig.json`, `jest.config.js`
- **Java**: `pom.xml`, `build.gradle`, `*.java`
- **C/C++**: `CMakeLists.txt`, `Makefile`, `*.cpp`, `*.c`

---

## Scientific Methodology

### Test Quality Metrics

**Coverage Thresholds:**
- < 60%: Focus on basic test creation
- 60-80%: Targeted refinement
- > 80%: Mutation testing + property tests

**Mutation Score Targets:**
- > 70% for covered code = good quality
- < 50% = weak tests, need improvement

**Success Criteria:**
- Coverage: >80% for critical code, >60% overall
- Mutation Score: >70% for covered code
- Pass Rate: 100%
- Test Speed: Full suite < 5 minutes

### Test Creation Heuristics

**Boundary Value Analysis:**
- For `n > 0`: Test with `1`, `0`, `-1`
- For `len(x) >= 1`: Test with `[]`, `[1]`, `[1,2]`
- For exact equality: Test `value`, `value-1`, `value+1`

**Error Path Coverage:**
- Every exception raised → test that raises it
- Every error check → test that triggers it
- Every null/none check → test with null/none

**Property Test Candidates:**
- Sorting functions (idempotent, preserves length, ordered)
- Serialization (roundtrip property)
- Mathematical operations (commutative, associative)
- Reversible operations (involution)

---

## Implementation Status

### Completed
- ✅ Competitive analysis
- ✅ Architecture design
- ✅ Directory structure implemented
- ✅ Tool manifest defined
- ✅ Skills created following obra patterns
- ✅ Benchmarking infrastructure (setup, run, evaluate, visualize)
- ✅ Virtual environment isolation per repo (no dependency conflicts)
- ✅ obra/superpowers integration script (`src/setup_obra.sh`)
- ✅ Incremental strategy for batch vs step-by-step comparison
- ✅ Documentation updated (CLAUDE.md, README.md)

### In Progress
- 🔄 CLI tools implementation (lib/atsr-tools/)
- 🔄 Skills testing with subagents

### TODO
- ⏳ Complete benchmark runs (3 strategies × 2 models × 3 repos = 18 runs)
- ⏳ Analysis of batch (aTSR) vs incremental approaches
- ⏳ Additional language support (Go, Rust, Ruby)

---

## Development Notes

### Key Decisions Made

**2025-11-05: Virtual environment isolation and benchmark improvements**
- Added isolated venv per test repo to prevent dependency conflicts
- Each repo gets `.venv/` during setup, activated during benchmarks
- Integrated obra/superpowers TDD skill (for reference/complementary use)
- Added "incremental" strategy to compare batch vs step-by-step approaches
- Now benchmarking 3 strategies: refine (aTSR batch), base (baseline), incremental (step-by-step)
- Updated all scripts and documentation to reflect improvements

**2025-11-04: Expanded from refinement-only to complete lifecycle**
- Initially planned only test refinement
- Realized: need test creation for zero-tests scenario
- Now provides complete solution: creation + refinement

**2025-11-04: Following obra/superpowers patterns**
- Analyzed obra's skill architecture
- Adopted their proven conventions
- Position as complementary (they have TDD, we have automation)

**2025-11-04: CLI tools for deterministic operations**
- Skills teach WHEN and HOW
- Tools do WHAT (deterministic, testable)
- Agents interpret tool output, don't copy bash scripts

### Lessons from Original Experiment

From `evaluation_testing/v2_results/improved-prompts/README.md`:

**What Worked:**
- Pre-execution context reduces token usage
- Simple prompts outperform complex workflows
- Baseline (77.5% coverage) beat original refine-tests.md (74.7%)

**What Didn't Work:**
- 860-line monolithic prompt (too complex)
- Inline bash scripts (agents copy code wastefully)
- No clear decision tree (agents wander)

**Our Solution:**
- Modular skills (focused, < 500 words each)
- CLI tools (agents invoke, don't copy)
- Clear workflow (decision tree in test-suite-management)

---

## Quirks and Gotchas

### Tool Development
- All tools must handle missing dependencies gracefully
- Provide helpful error messages with installation instructions
- Support multiple versions of tools (e.g., pytest vs unittest)

### Skill Testing
- MUST test with subagents before deploying (obra pattern)
- Create pressure scenarios to test skill robustness
- Document rationalizations agents use to skip steps

### Multi-Language Challenges
- Framework detection must be reliable
- Coverage output formats vary wildly
- Mutation testing tools have different maturity levels

---

## Future Enhancements

### Potential Additions
- Integration testing skill
- Performance testing skill
- Security testing patterns
- Snapshot testing guidance

### Benchmark Extensions
- Test on larger codebases (> 5000 LOC)
- More languages (Go, Rust, Ruby)
- Different domains (web, CLI, data science)

---

## Resources

### External References
- obra/superpowers: https://github.com/obra/superpowers
- Claude Code Skills Docs: https://docs.claude.com/en/docs/claude-code/skills.md
- Our original experiment: `evaluation_testing/v2_results/`

### Internal Files
- Original monolithic prompt: `src/refine-tests.md`
- Benchmark scripts: `src/evaluate_all.sh`, `src/run_benchmark.sh`
- Test repos: `examples/repos_reduced/`

---

*This file serves as the project memory. Update it after significant decisions, architectural changes, or when discovering quirks that future sessions need to know.*
