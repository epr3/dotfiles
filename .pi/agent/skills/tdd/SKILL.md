---
name: tdd
description: Test-driven development via a red-green-refactor loop, one vertical slice at a time. Use when building a feature or fixing a bug test-first, when the user mentions TDD, red-green-refactor, integration tests, or test-first development, or when a change needs a tight feedback loop. Tests verify behaviour through public interfaces, not implementation details.
---

# Test-Driven Development

## Philosophy

**Core principle**: tests verify behaviour through public interfaces, not implementation details. The code can change entirely; the tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe *what* the system does, not *how* it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (querying a database directly instead of going through the interface). The warning sign: the test breaks when you refactor but behaviour hasn't changed. Rename an internal function and tests fail -> those tests were testing implementation, not behaviour.

**Tautological tests** restate the implementation inside the assertion, so they pass by construction and give zero confidence. When the expected value is computed the way the code computes it — `expect(add(a, b)).toBe(a + b)`, snapshotting a figure you derived by hand the same way the code does, asserting a constant equals itself — the test can never disagree with the code: break the code wrong and the assertion breaks wrong with it. The expected value must come from an independent source of truth — a known-good literal, a worked example, the spec.

See [tests.md](./tests.md) for examples and [mocking.md](./mocking.md) for mocking guidelines.

## Anti-pattern: horizontal slices

**DO NOT write all tests first, then all implementation.** That is "horizontal slicing" — treating RED as "write all tests" and GREEN as "write all code." It produces **crap tests**:

- Tests written in bulk test *imagined* behaviour, not *actual* behaviour.
- You end up testing the *shape* of things (data structures, signatures) rather than user-facing behaviour.
- Tests become insensitive to real changes — they pass when behaviour breaks and fail when behaviour is fine.
- You outrun your headlights, committing to test structure before understanding the implementation.

**Correct approach**: vertical slices via tracer bullets. One test -> one implementation -> repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behaviour matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED->GREEN: test1->impl1
  RED->GREEN: test2->impl2
  RED->GREEN: test3->impl3
  ...
```

## Workflow

When the work is a tracked issue, `tdd` runs on top of [`implement`](../implement/SKILL.md): follow its flow — load the issue, build the slice, verify, set status — and iterate on the implement step with the red-green-refactor loop below (one failing test, then the minimal code to pass, then refactor). Standalone, with no issue in play, run the loop directly.

### 1. Planning

Orient to the project's domain model first: test names and interface vocabulary should match the glossary in this branch's context worktree (`CONTEXT.md`; see [../domain-modeling/CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). A new domain term you surface while testing -> write it into the worktree per [domain-modeling](../domain-modeling/SKILL.md).

Before writing any code:

- Confirm what interface changes are needed.
- Confirm which behaviours to test, and prioritise them.
- Identify opportunities for [deep modules](./deep-modules.md) (small interface, deep implementation) — see [codebase-design](../codebase-design/SKILL.md) for the full module/seam/adapter/leverage/locality vocabulary.
- Design interfaces for [testability](./interface-design.md).
- List the behaviours to test (not implementation steps).
- Get approval on the plan: `question` tool if available, else prose (2-4 options, `(recommended)`, one-line reason, stop) — confirm the public interface and the behaviours that matter most before writing code.

**You can't test everything.** Confirm exactly which behaviours matter most; focus effort on critical paths and complex logic, not every possible edge case.

### 2. Tracer bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   write the test for the first behaviour -> test fails
GREEN: write minimal code to pass        -> test passes
```

This is your tracer bullet — it proves the path works end-to-end.

### 3. Incremental loop

For each remaining behaviour:

```
RED:   write the next test -> fails
GREEN: minimal code to pass -> passes
```

Rules:

- One test at a time.
- Only enough code to pass the current test.
- Don't anticipate future tests.
- Keep tests focused on observable behaviour.
- After GREEN, `lsp_diagnostics` on the touched files is the fast first check before moving on — fix type errors + missing imports immediately (prefer LSP over grep when available).

### 4. Refactor

After all tests pass, look for [refactor candidates](./refactoring.md):

- Extract duplication.
- Deepen modules (move complexity behind simple interfaces).
- Apply SOLID principles where natural.
- Consider what the new code reveals about existing code.
- Before renaming or changing a shared interface, run `lsp_references` on it first — grep misses dynamic + re-exported usages and over-matches common names.
- Run tests after each refactor step; `lsp_diagnostics` on touched files alongside catches type errors before the suite runs.

**Never refactor while RED.** Get to GREEN first.

## Checklist per cycle

```
[ ] Test describes behaviour, not implementation
[ ] Test uses the public interface only
[ ] Test would survive an internal refactor
[ ] Expected values are independent literals, not recomputed from the code
[ ] Code is minimal for this test
[ ] No speculative features added
```
