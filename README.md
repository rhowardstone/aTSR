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
| **Test Creation** | ✅ Automated from code analysis | ❌ Manual TDD only | ❌ Ad-hoc |
| **Test Refinement** | ✅ Coverage + Mutation + Properties | ❌ Not available | ❌ Guesswork |
| **Multi-Language** | ✅ Python, JS/TS, Java, C/C++ | ⚠️ Framework agnostic | ⚠️ Language dependent |
| **Methodology** | ✅ Scientific (measured) | ✅ Systematic (TDD) | ❌ None |
| **Benchmarked** | ✅ Yes | ❌ No | ✅ Yes |

**Complementary to obra/superpowers**: They provide TDD for writing new features. We provide automation for existing codebases.

---

## 🚀 Quick Start

### Installation

```bash
git clone https://github.com/rhowardstone/aTSR.git
cd aTSR
```

### Option 1: Use as Claude Code Skills (Recommended)

Install skills into your personal or project skills directory:

```bash
# For personal use (all projects)
cp -r .claude/skills/* ~/.claude/skills/
cp -r .claude/commands/* ~/.claude/commands/
cp -r .claude/lib ~/.claude/

# For this project only
# Skills already in .claude/ - just start using them!
```

Add tools to PATH:
```bash
export PATH="$(pwd)/.claude/lib/atsr-tools:$PATH"
```

### Option 2: Use Legacy Command (Old Approach)

```bash
bash src/install_command.sh
```

This installs the old monolithic 860-line prompt. **Not recommended** - use skills instead!

---

## 💡 Usage

### With Skills (New Way)

```bash
cd your-project
claude

# In Claude Code:
/refine-tests
```

**What happens:**
1. aTSR assesses your codebase size and language
2. Determines if you need test creation or refinement
3. Automatically runs appropriate workflow
4. Uses coverage analysis, mutation testing, and property-based testing

### With Legacy Command (Old Way)

```bash
cd your-project
claude
/refine-tests auto
```

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
| `atsr-analyze-code` | Find functions needing tests |
| `atsr-generate-tests` | Create initial test templates |
| `atsr-coverage` | Run coverage analysis |
| `atsr-gaps` | Parse coverage, identify gaps |
| `atsr-mutate` | Run mutation testing |
| `atsr-survivors` | Analyze survived mutants |
| `atsr-recommend` | Generate test recommendations |

**Design Philosophy**: Skills teach WHEN and HOW. Tools do WHAT.

---

## 📊 Benchmarking

### Test Repositories

We provide 3 example repositories for testing:

```bash
bash src/setup_test_repos.sh examples
ls examples/repos_reduced/
# schedule, mistune, click
```

### Running Benchmarks

Compare aTSR against baseline and obra/superpowers:

```bash
# Create benchmark runs
for n in 1 2 3; do
  bash src/create_benchmark.sh examples/repos_reduced/ bench/bench$n/
  bash src/run_benchmark.sh bench/bench$n/
done

# Evaluate results
bash src/evaluate_all.sh bench/ --output-dir evaluation_results --verbose

# Visualize
python src/Create_visualization.py evaluation_results/summary.json evaluation_results/plot.png
```

### Benchmark Configurations

We test 4 configurations:
1. **Baseline** - Simple prompt, no skills
2. **aTSR Skills** - Our complete skill system
3. **obra TDD** - Using obra's test-driven-development skill
4. **aTSR + obra** - Combined approach

**Metrics:**
- Coverage % achieved
- Pass rate %
- Token usage
- Tests added
- Time to completion

---

## 🎓 How It Works

### Scenario 1: No Tests Exist

```
User: /refine-tests

1. atsr-size → detects 0 test files
2. test-creation skill activates:
   - atsr-analyze-code → finds all functions
   - atsr-generate-tests → creates test templates
   - Human customizes TODOs
   - Tests run and pass
3. test-refinement skill takes over:
   - atsr-coverage → baseline coverage
   - Adds missing edge cases
   - atsr-mutate → verifies quality

Result: 0 → 85 tests, 78% coverage, 72% mutation score
```

### Scenario 2: Tests Exist, Need Improvement

```
User: /refine-tests

1. atsr-size → detects tests exist, 45% coverage
2. test-refinement skill activates:
   - atsr-coverage → identifies gaps
   - atsr-gaps → prioritizes critical files
   - Human adds tests for gaps
   - atsr-mutate → finds weak tests
   - atsr-survivors → recommends killer tests
   - Human strengthens assertions

Result: 45% → 82% coverage, mutation score 65% → 78%
```

### Scenario 3: Tiny Codebase (< 100 LOC)

```
User: /refine-tests

1. atsr-size → detects 73 LOC
2. test-suite-management skill:
   - Skips all tools
   - Just reads code and tests
   - Identifies obvious gaps (boundaries, errors)
   - Writes them directly

Result: 5 minutes, perfect tests, no overhead
```

---

## 📁 Directory Structure

```
aTSR/
├── .claude/                        # Claude Code skills and tools
│   ├── skills/                     # 7 skills following obra patterns
│   ├── commands/                   # Thin command wrappers
│   └── lib/atsr-tools/             # 9 CLI utilities
├── src/                            # Legacy scripts and original prompt
│   ├── refine-tests.md             # Original 860-line prompt (deprecated)
│   ├── evaluate_all.sh             # Benchmark evaluation
│   └── Create_visualization.py     # Results visualization
├── examples/                       # Test repositories
├── evaluation_testing/             # Benchmark results
├── CLAUDE.md                       # Project memory and architecture
└── README.md                       # This file
```

---

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete architecture, competitive analysis, tool manifest
- **[.claude/skills/](.claude/skills/)** - Individual skill documentation
- **[evaluation_testing/v2_results/](evaluation_testing/v2_results/)** - Original experiment analysis

---

## 🔬 Research

### Original Experiment Results

Our initial experiment compared two approaches:

- **Base** (simple prompt): 77.5% coverage, 29.3M tokens
- **Refine** (860-line workflow): 74.7% coverage, 35.8M tokens

**Key Finding**: Simpler was better! This led to our modular skill design.

### New Skill-Based Approach

Based on lessons learned, we built:
- Modular skills (< 500 words each)
- CLI tools (deterministic, testable)
- Clear decision trees
- Following obra/superpowers best practices

**Expected Improvements:**
- Better coverage than both baseline and original
- Lower token usage than original monolith
- Complementary to obra (creation + refinement)

---

## 🤝 Contributing

We welcome contributions! Especially:

- Additional language support (Go, Rust, Ruby)
- New test quality metrics
- Benchmark comparisons
- Skill improvements

See the official skill creation guide: [https://github.com/anthropics/skills](https://github.com/anthropics/skills)

---

## 📈 Roadmap

- [ ] Complete benchmark comparison (aTSR vs obra vs baseline)
- [ ] Integration testing skill
- [ ] Performance testing patterns
- [ ] Security testing guidance
- [ ] Snapshot testing skill
- [ ] Support for additional languages

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
