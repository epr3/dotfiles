---
name: tdd
description: Test-driven development via a red-green-refactor loop, one vertical slice at a time. Use when the user wants work done test-first, mentions TDD or red-green-refactor, or when a change needs a tight feedback loop.
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

## Workflow

When the work is a tracked issue, `tdd` runs on top of `implement`: follow its flow — load the ticket, build the slice, verify, set status — and iterate on the build step with the loop below. Standalone, with no ticket in play, run the loop directly.

### 1. Planning

Orient to the project's domain model first: test names and interface vocabulary should match the glossary in this branch's context worktree (`CONTEXT.md`; see [../domain-modeling/CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). A new domain term you surface while testing -> write it into the worktree per `domain-modeling`.

Before writing any code:

- Confirm what interface changes are needed.
- Identify opportunities for [deep modules](./deep-modules.md) — see `codebase-design` for the full module/seam/adapter/leverage/locality vocabulary.
- Design interfaces for [testability](./interface-design.md).
- List the behaviours to test (not implementation steps) and prioritise them.
- Get approval on the plan — the public interface, and which behaviours matter most — as one **round** in the `grilling` skill's question format.

**You can't test everything.** Focus effort on critical paths and complex logic, not every possible edge case.

### 2. The loop

```
RED:   write ONE test for the next behaviour -> it fails
GREEN: write the minimal code to pass        -> it passes
```

The first pass through is your **tracer bullet** — it proves the path works end-to-end. Then repeat, one behaviour at a time, each test responding to what the last cycle taught you.

### 3. Refactor

After all tests pass, look for [refactor candidates](./refactoring.md):

- Extract duplication.
- Deepen modules (move complexity behind simple interfaces).
- Apply SOLID principles where natural.
- Consider what the new code reveals about existing code.
- Run tests after each refactor step.

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
