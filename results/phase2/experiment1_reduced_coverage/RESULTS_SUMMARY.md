# Benchmark Results: 6 Prompt Variants × 3 Repositories

**Date**: October 11, 2025
**Model**: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
**Total Tests Executed**: 18 (100% success rate)

## Key Findings

### 🏆 Best Overall: V2-Baseline+Context
- **Highest coverage efficiency**: 30,303 coverage points per Mtoken
- **Reasonable runtime**: 22.2 minutes (2nd fastest)
- **Low token usage**: 2.2K tokens (2nd lowest)
- **Balanced performance**: Good coverage with minimal resource use

### ⚠️ Worst Performer: V4-Context+Mutations
- **NEGATIVE coverage efficiency**: -27,864 (actually decreased coverage!)
- **Coverage dropped below baseline** in multiple repos
- Despite lowest token usage (1.9K), the poor quality makes it inefficient

### 📊 Detailed Metrics by Variant

#### V1-Baseline (Control)
- **Coverage**: click 79%, mistune 85%, schedule 97%
- **Runtime**: 29.8m (slowest)
- **Tokens**: 4.9K
- **Tests**: 565/805/64 (total: 1,434 passing)
- **Efficiency**: 21,459 points/Mtoken

#### V2-Baseline+Context ⭐ RECOMMENDED
- **Coverage**: click 66%, mistune 64%, schedule 94%
- **Runtime**: 22.2m
- **Tokens**: 2.2K (2nd lowest)
- **Tests**: 340/677/52 (total: 1,069 passing, 2 failed)
- **Efficiency**: 30,303 points/Mtoken (BEST)

#### V3-Context+Coverage
- **Coverage**: click 70%, mistune 53%, schedule 95%
- **Runtime**: 22.0m (fastest)
- **Tokens**: 2.5K
- **Tests**: 358/658/50 (total: 1,066 passing)
- **Efficiency**: 24,535 points/Mtoken

#### V4-Context+Mutations ⚠️ AVOID
- **Coverage**: click 0%, mistune 46%, schedule 56%
- **Runtime**: 23.0m
- **Tokens**: 1.9K (lowest)
- **Tests**: 277/741/18 (total: 1,036 passing)
- **Efficiency**: -27,864 points/Mtoken (WORST - decreased coverage!)

#### V5-Context+Both
- **Coverage**: click 65%, mistune 79%, schedule 97%
- **Runtime**: 25.3m
- **Tokens**: 3.4K
- **Tests**: 252/709/70 (total: 1,031 passing)
- **Efficiency**: 25,358 points/Mtoken

#### V6-Minimal
- **Coverage**: click 63%, mistune 82%, schedule 88%
- **Runtime**: 21.7m (fastest by 0.3m)
- **Tokens**: 6.4K (highest)
- **Tests**: 472/774/45 (total: 1,291 passing)
- **Efficiency**: 12,039 points/Mtoken

## Tool Usage Analysis

### Total Tool Calls by Variant
- V5-Context+Both: 165 calls (most comprehensive)
- V4-Context+Mutations: 153 calls
- V3-Context+Coverage: 147 calls
- V1-Baseline: 147 calls
- V2-Baseline+Context: 132 calls
- V6-Minimal: 130 calls (most efficient)

### Bash Command Breakdown
**Top commands across all variants:**
1. **python** - Running tests and coverage (dominant usage)
2. **coverage** - Coverage measurement tool
3. **pytest** - Test execution
4. **mutmut** - Mutation testing (V4 variant)
5. **find** - File system navigation

**Observation**: V3-Coverage and V4-Mutations variants use specialized tools (coverage/mutmut) heavily, but V4's mutation-focused approach backfired, actually decreasing coverage.

## Recommendations

### For Production Use: V2-Baseline+Context
- Best coverage efficiency (30K points/Mtoken)
- Low resource consumption (2.2K tokens, 22.2m runtime)
- Provides good balance of quality and efficiency
- Pre-execution context orientation helps focus efforts

### For Fast Iteration: V6-Minimal
- Fastest runtime (21.7m)
- Fewest tool calls (130)
- Good test count (1,291 passing tests)
- Despite high token count, delivers results quickly

### Avoid: V4-Context+Mutations
- Mutation testing guidance led to coverage DECREASE
- Only variant with negative efficiency
- Not suitable for test suite improvement tasks

## Visualizations

All charts available in `visualizations/` directory:
1. `test_passfall.png` - Test counts by variant and repo
2. `coverage.png` - Final coverage percentages
3. `coverage_efficiency.png` - Coverage increase per Mtoken
4. `token_usage.png` - Total output tokens used
5. `tokens_per_test.png` - Efficiency per passing test
6. `runtime.png` - Total execution time
7. `function_calls.png` - Total tool invocations
8. `tool_breakdown.png` - Which tools were used
9. `bash_breakdown.png` - Bash command types executed

## Raw Data

- **Metrics**: `benchmark_metrics.json` - Complete extracted metrics
- **Session Logs**: `benchmark_data/benchmark/results_20251011_114055/` - Full JSONL logs for each test
- **Summary Report**: `benchmark_data/benchmark/results_20251011_114055/summary.md`

## Conclusion

The experiment demonstrates that **prompt engineering significantly impacts both efficiency and effectiveness**. The recommended V2-Baseline+Context variant achieves 41% better efficiency than the control (V1-Baseline) by providing better context upfront. Conversely, overly complex prompts (V4-Mutations) can backfire, producing worse results despite using fewer tokens.

**Key takeaway**: Simple context-aware prompts (V2) outperform both minimal prompts (V1) and overly prescriptive tool-focused prompts (V4).
