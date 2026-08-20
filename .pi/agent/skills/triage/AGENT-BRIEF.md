# Agent Brief

An **Agent Brief** is the authoritative specification attached when an issue or PR moves to `ready-for-agent`. The original body, discussion, and PR diff are context; the brief is the contract an AFK agent implements.

For an issue, it states the change to build. For a PR, it states what remains to do **to the existing diff**: finish it, close gaps, or address review points.

Three principles bind it:

- **Durable**: no file paths or line numbers that go stale. Reference types, function signatures, configuration shapes, and behavioural contracts instead.
- **Behavioural**: describe what the system should do, not how to code it.
- **Testable**: acceptance criteria are independently verifiable checkboxes.

State explicit **out of scope** boundaries so the agent does not gold-plate adjacent work.

## Template

```markdown
## Agent Brief

**Category:** bug | enhancement
**Summary:** one line.

**Current behaviour:** the status quo, the confirmed repro, or for a PR, the state of its existing diff.

**Desired behaviour:** specific goals, including edge cases and error conditions.

**Key interfaces:** the types, function signatures, or config shapes involved, and their behavioural contract.

**Acceptance criteria:**
- [ ] independently verifiable outcome
- [ ] independently verifiable outcome

**Out of scope:** explicit boundaries, so the agent does not gold-plate.
```

## Examples

### Good PR brief

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Finish the contributor's `--json` output flag for `triage list`.

**Current behaviour:** The PR serializes successful issue lists as JSON. Errors remain human text, and the flag has no test coverage.

**Desired behaviour:** With `--json`, success and errors are well-formed JSON on stdout without changing exit codes. Human-readable output is unchanged when the flag is absent.

**Key interfaces:** The command's error path emits `{ "error": string }` under `--json`; reuse the serializer already introduced by the PR.

**Acceptance criteria:**
- [ ] `triage list --json` emits valid JSON for success and error cases
- [ ] exit codes match the non-JSON command
- [ ] tests cover one success and one error case
- [ ] default output is unchanged

**Out of scope:** adding `--json` to other commands or changing the existing success-payload shape.
```

### Bad brief

```markdown
## Agent Brief

**Summary:** Fix the triage bug.

**What to do:** The triage thing is broken. Look at the main file around line 150 and fix it.
```

This is vague, implementation-coupled, stale-prone, and lacks acceptance criteria and scope boundaries.
