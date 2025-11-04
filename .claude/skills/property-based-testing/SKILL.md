---
name: property-based-testing
description: Use when testing algorithmic code (sorting, parsing, math, transforms) - generates property tests that verify invariants hold across thousands of random inputs instead of hand-picking test cases
---

# Property-Based Testing

## Overview

Test properties that should ALWAYS be true, across random inputs.

**Core principle:** Don't guess test cases. Test the rules.

## When to Use

**Good for:**
- Sorting functions
- Serialization/deserialization
- Mathematical operations
- Parsers
- Data transformations

**Signs a function needs property tests:**
- Pure function (no side effects)
- Deterministic output
- Clear invariants
- Works on many input types

## When NOT to Use

- UI code
- Database operations
- Network calls
- One-off business logic

## Common Properties

### Idempotence
Operation twice = operation once

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_idempotent(data):
    once = sorted(data)
    twice = sorted(once)
    assert once == twice  # sort(sort(x)) == sort(x)
```

### Roundtrip
Encode → Decode = Identity

```python
@given(st.text())
def test_json_roundtrip(data):
    encoded = json.dumps(data)
    decoded = json.loads(encoded)
    assert decoded == data
```

### Invariants
Properties that never change

```python
@given(st.lists(st.integers()))
def test_sort_preserves_length(data):
    assert len(sorted(data)) == len(data)

@given(st.lists(st.integers()))
def test_sort_is_ordered(data):
    result = sorted(data)
    for i in range(len(result) - 1):
        assert result[i] <= result[i+1]
```

### Commutativity
Order doesn't matter

```python
@given(st.integers(), st.integers())
def test_add_commutative(a, b):
    assert add(a, b) == add(b, a)
```

## Python: Hypothesis

```bash
pip install hypothesis
```

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_my_function(a, b):
    result = my_function(a, b)
    # Assert properties
```

## JavaScript: fast-check

```bash
npm install --save-dev fast-check
```

```javascript
const fc = require('fast-check');

test('myFunction properties', () => {
  fc.assert(fc.property(
    fc.integer(), fc.integer(),
    (a, b) => {
      const result = myFunction(a, b);
      // Check properties
      return result !== null;
    }
  ));
});
```

## Identifying Property Test Candidates

Run `atsr-analyze-code` and look for:

**Sorting:**
- Idempotent: `sort(sort(x)) == sort(x)`
- Preserves length: `len(sort(x)) == len(x)`
- Ordered: `result[i] <= result[i+1]`

**Serialization:**
- Roundtrip: `decode(encode(x)) == x`

**Reversible:**
- Involution: `reverse(reverse(x)) == x`

**Math:**
- Commutative: `f(a,b) == f(b,a)`
- Associative: `f(f(a,b),c) == f(a,f(b,c))`

## The Bottom Line

Example tests check specific cases. Property tests check the rules.

Identify invariants → Express as properties → Let tool generate 1000s of test cases.
