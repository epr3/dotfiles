# Agent Brief

A brief that lets an AFK agent implement the issue with no human context. Three principles bind it:

- **Durable** — no file paths or line numbers that go stale. Reference types, function signatures, and behavioural contracts instead.
- **Behavioural** — describe what the system should do, not how to code it.
- **Testable** — acceptance criteria are concrete checkboxes an agent can verify.

## Template

```
## Agent Brief

**Category:** bug | enhancement
**Summary:** one line.

**Current behaviour:** the status quo, or the bug (with the confirmed repro if there is one).

**Desired behaviour:** specific goals, including edge cases.

**Key interfaces:** the types, function signatures, or config shapes involved.

**Acceptance criteria:**
- [ ] verifiable outcome
- [ ] verifiable outcome

**Out of scope:** explicit boundaries, so the agent doesn't gold-plate.
```
