# aTSR - Agentic Test Suite Refinement

**Complete test automation for Claude Code**: From zero tests to comprehensive, high-quality test suites.

Created as a project for CSE5095: AI for Software Development (Fall 2025)

---

## 🎯 What is aTSR?

aTSR provides **end-to-end test lifecycle management** through Claude Code skills:

- **Test Creation**: Automated initial test suite generation from source code analysis
- **Test Refinement**: Systematic improvement using coverage analysis and mutation testing
- **Multi-Language**: Python, JavaScript/TypeScript, Java, C/C++ support
- **Scientific Methodology**: Proven approach with benchmarked results

### How We Compare

| Feature | aTSR | obra/superpowers | Baseline |
|---------|------|------------------|----------|
| **Test Creation** | ✅ Batch analysis (398 functions → 50 tests) | ⚠️ Incremental TDD (test-by-test) | ❌ Ad-hoc |
| **Test Refinement** | ✅ Coverage + Mutation + Properties | ❌ Not available | ❌ Guesswork |
| **Use Case** | Existing codebases needing tests | New feature development | Any |
| **Approach** | Analysis-driven (batch) | Test-first discipline (incremental) | Prompt-based |
| **Multi-Language** | ✅ Python, JS/TS, Java, C/C++ | ⚠️ Framework agnostic | ⚠️ Language dependent |
| **Methodology** | ✅ Scientific (measured) | ✅ Systematic (TDD) | ❌ None |
| **Benchmarked** | ✅ Yes | ❌ No | ✅ Yes |

**Complementary to obra/superpowers**:
- **obra TDD**: Best for writing NEW features (test-first, incremental RED-GREEN-REFACTOR)
- **aTSR**: Best for EXISTING codebases (batch analysis, coverage-driven refinement)

---

## 🚀 Quick Start

### Installation

```bash
git clone https://github.com/rhowardstone/aTSR.git
cd aTSR
```

### Install Skills

```bash
# For personal use (all projects)
cp -r .claude/skills/* ~/.claude/skills/
cp -r .claude/commands/* ~/.claude/commands/
cp -r .claude/lib ~/.claude/

# Add tools to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
export PATH="$(pwd)/.claude/lib/atsr-tools:$PATH"
```

---

## 💡 Usage

```bash
cd your-project
claude

# In Claude Code:
/refine-tests
```

**What happens:**
1. aTSR assesses your codebase size and language
2. Determines if you need test creation or refinement
3. Automatically runs appropriate workflow:
   - **No tests?** → Analyzes code, generates test suite
   - **Some tests?** → Identifies gaps via coverage, improves quality via mutations
   - **Good tests?** → Adds property-based tests for algorithms

---

## 🏗️ Architecture

### Skills

aTSR provides 7 specialized skills:

| Skill | Purpose |
|-------|---------|
| **test-suite-management** | Main orchestrator - routes to creation or refinement |
| **test-creation** | Generate initial tests from code analysis (zero → baseline) |
| **test-refinement** | Systematic improvement (baseline → comprehensive) |
| **coverage-analysis** | Find and prioritize test gaps |
| **mutation-testing** | Verify test quality by introducing bugs |
| **property-based-testing** | Add algorithmic property tests |
| **test-gap-analysis** | Prioritize gaps by criticality |

### CLI Tools

9 deterministic utilities in `.claude/lib/atsr-tools/`:

| Tool | Purpose |
|------|---------|
| `atsr-size` | Assess codebase (LOC, test ratio, approach) |
| `atsr-detect` | Detect language, framework, test runner |
| `atsr-analyze-code` | Find functions needing tests (AST-based) |
| `atsr-generate-tests` | Create initial test templates |
| `atsr-coverage` | Run coverage analysis |
| `atsr-gaps` | Parse coverage, identify gaps |
| `atsr-mutate` | Run mutation testing |
| `atsr-survivors` | Analyze survived mutants |
| `atsr-recommend` | Generate test recommendations |

**Design Philosophy**: Skills teach WHEN and HOW. Tools do WHAT.

---

## 📊 Benchmarking

### What We Test

We compare **3 approaches** on the same codebases:

1. **Baseline**: Simple prompt asking to improve tests
2. **aTSR Skills**: Our complete skill system (`/refine-tests`)
3. **[Planned] obra TDD**: Using obra's test-driven-development skill

### Test Repositories

We use 3 real-world Python projects:

- **schedule** (~400 LOC, scheduling library)
- **mistune** (~2,600 LOC, Markdown parser)
- **click** (~3,500 LOC, CLI framework)

### How It Works

```bash
# 1. Set up test repos (downloads and prepares them)
bash src/setup_test_repos.sh examples

# 2. Create benchmark copies (4 configurations × 3 repos = 12 runs)
for n in 1 2 3; do
  bash src/create_benchmark.sh examples/repos_reduced/ bench/bench$n/
  bash src/run_benchmark.sh bench/bench$n/
done

# 3. Evaluate results
bash src/evaluate_all.sh bench/ --output-dir evaluation_results

# 4. Visualize
python src/Create_visualization.py evaluation_results/summary.json results.png
```

**What gets measured:**
- Coverage % achieved
- Pass rate % (tests passing / total tests)
- Token usage (from Claude API logs)
- Tests added (count)
- Time to completion

### Current Limitations

⚠️ **Environment Isolation**: Benchmarks run **in series** using the **same Python environment**. Dependencies must be pre-installed globally. Future improvement: Use venvs per run.

⚠️ **obra Comparison**: Not yet implemented. Would require adding obra/superpowers skills to the test environment.

---

## 🎓 How It Works

### Scenario 1: No Tests Exist

```
User: /refine-tests

1. atsr-size → detects 0 test files
2. test-creation skill activates:
   - atsr-analyze-code → finds all 398 functions
   - atsr-generate-tests → creates test templates
   - Human customizes TODOs (boundaries, errors, edge cases)
   - Tests run and pass
3. test-refinement skill takes over:
   - atsr-coverage → measures baseline coverage
   - Adds missing edge cases
   - atsr-mutate → verifies test quality

Result: 0 → 85 tests, 78% coverage, 72% mutation score
```

### Scenario 2: Tests Exist, Need Improvement

```
User: /refine-tests

1. atsr-size → detects tests exist, 45% coverage
2. test-refinement skill activates:
   - atsr-coverage → identifies gaps
   - atsr-gaps → prioritizes critical files (business logic first)
   - Human adds tests for gaps
   - atsr-mutate → finds weak tests (boundary conditions, null checks)
   - atsr-survivors → recommends killer tests
   - Human strengthens assertions

Result: 45% → 82% coverage, mutation score 65% → 78%
```

### Scenario 3: Tiny Codebase (< 100 LOC)

```
User: /refine-tests

1. atsr-size → detects 73 LOC
2. test-suite-management skill:
   - Skips all tools (overhead not worth it)
   - Just reads code and tests directly
   - Identifies obvious gaps (boundaries, errors)
   - Writes them directly

Result: 5 minutes, perfect tests, zero tool overhead
```

---

## 📁 Project Structure

```
aTSR/
├── .claude/                        # Claude Code skills and tools
│   ├── skills/                     # 7 modular skills (<500 words each)
│   ├── commands/                   # Thin command wrappers
│   └── lib/atsr-tools/             # 9 CLI utilities
├── src/                            # Benchmark infrastructure
│   ├── create_benchmark.sh         # Set up benchmark runs
│   ├── run_benchmark.sh            # Execute benchmarks
│   ├── evaluate_all.sh             # Analyze results
│   ├── setup_test_repos.sh         # Download test repositories
│   └── Create_visualization.py     # Generate plots
├── initial_experiments/            # Original research experiments
│   ├── monolithic_prompt.md        # Original 860-line prompt
│   └── prompt_variants/            # 6 prompt design iterations
├── examples/                       # Generated test repos (gitignored)
├── CLAUDE.md                       # Project memory and architecture
└── README.md                       # This file
```

---

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete architecture, competitive analysis, tool manifest, design decisions
- **[.claude/skills/](.claude/skills/)** - Individual skill documentation (WHEN to use, HOW to interpret)
- **[initial_experiments/](initial_experiments/)** - Original research: monolithic prompt evolution

---

## 🔬 Research

### Key Findings from Initial Experiments

Our initial experiment (in `initial_experiments/`) compared prompt designs:

- **Baseline** (simple prompt): **77.5% coverage**, 29.3M tokens
- **Monolithic** (860-line workflow): **74.7% coverage**, 35.8M tokens ❌

**Lesson learned**: Simpler was better! Complex inline scripts caused agents to copy code wastefully.

### Skill-Based Redesign

Based on these findings, we built:
- ✅ Modular skills (< 500 words each) - no inline scripts
- ✅ CLI tools (deterministic, testable) - agents invoke, don't copy
- ✅ Clear decision trees (test-suite-management routes appropriately)
- ✅ Following obra/superpowers best practices

**Expected improvements:**
- Better coverage than baseline (systematic vs ad-hoc)
- Lower tokens than monolithic (no script copying)
- Complementary to obra (batch vs incremental)

---

## 🤝 Contributing

We welcome contributions! Especially:

- Additional language support (Go, Rust, Ruby)
- New test quality metrics
- obra/superpowers integration for benchmarking
- Virtual environment isolation for benchmarks
- Skill improvements

---

## 📈 Roadmap

- [ ] Complete benchmark comparison (aTSR vs obra vs baseline)
- [ ] Add venv isolation to benchmarks
- [ ] Integration testing skill
- [ ] Performance testing patterns
- [ ] Security testing guidance
- [ ] Snapshot testing skill

---

## 📄 License

MIT License - see LICENSE file

---

## 🙏 Acknowledgments

- **obra/superpowers** - Inspiration for skill architecture and best practices
- **Claude Code team** - Skills system and documentation
- **CSE5095** - Course project framework

---

## 📞 Contact

- **Issues**: https://github.com/rhowardstone/aTSR/issues
- **Progress Demo**: https://kaltura.uconn.edu/media/Kaltura+Capture+recording+-+October+6th+2025%2C+8%3A39%3A54+am/1_565tve3c

---

**aTSR**: Because test automation should be automatic.
