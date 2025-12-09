# 10.6M Token Anomaly: Opus vs Sonnet

**Phase**: Phase 1 (Base vs Refine)
**Repository**: click
**Strategy**: base
**Anomaly**: Opus used 10.6M tokens vs Sonnet's 2.4M (4.4x more)

## Token Breakdown

### Sonnet (click/base)
```json
{
  "message_count": 47,
  "tokens": {
    "total": 2374981,
    "input": 255,
    "output": 1192,
    "cache_creation": 167502,
    "cache_read": 2206032
  }
}
```

### Opus (click/base)
```json
{
  "message_count": 161,
  "tokens": {
    "total": 10623552,
    "input": 226,
    "output": 774,
    "cache_creation": 195023,
    "cache_read": 10427529
  }
}
```

## Key Observation

The `cache_read` dominates both totals:
- Sonnet: 2.2M cache_read (93% of total)
- Opus: 10.4M cache_read (98% of total)

Opus's cache_read is **4.7x larger** because it accumulated more context over more iterations.

## Tool Call Comparison

| Metric | Sonnet | Opus |
|--------|--------|------|
| JSONL lines | 91 | 247 |
| Messages | 47 | 161 |
| Tool calls | 43 | 85 |

### Tool Distribution

**Sonnet (43 calls)**:
- Bash: 15
- Edit: 12
- TodoWrite: 8
- Read: 5
- Write: 3

**Opus (85 calls)**:
- Bash: 27
- Edit: 25
- Grep: 12
- Read: 11
- TodoWrite: 7
- Write: 3

## What Opus Was Doing

Activity log from the session shows repeated fix cycles:

```
Message 40: "I see. The base class expects source_template to be defined."
Message 70: "Let me fix these issues:"
Message 80: "Let me debug this test to see what's actually returned:"
Message 90: "Let me create tests for the termui module:"
Message 100: "Now let me also remove the test that uses get_terminal_size:"
Message 110: "Let me check for _getchar:"
Message 120: "Let me fix the LazyFile test issue:"
Message 130: "Let me check what functions are actually available in utils:"
```

## Root Cause

Click has **190 existing baseline tests**. The agent had to:
1. Understand the existing test structure
2. Write new tests that integrate with existing fixtures
3. Handle compatibility issues when tests failed
4. Debug and fix failing tests iteratively

Opus's thoroughness led to:
- More exploration (12 Grep calls vs 0 for Sonnet)
- More iterations (25 Edits vs 12)
- More context accumulation per iteration
- Compounding cache_read costs

## The Math

Each message in an LLM conversation includes all previous context. With 161 messages averaging ~65K tokens of context each:

```
161 messages × 65K avg context ≈ 10.5M tokens
```

Sonnet's 47 messages with smaller context windows stayed under 2.5M.

## Lesson

More capable models may explore more thoroughly, but this comes with token costs that compound over long sessions. For test generation on large codebases with existing tests, the integration overhead can dominate.

**Sonnet achieved similar coverage (64% vs 67%) with 4.4x fewer tokens.**
