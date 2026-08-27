# Review disciplines stay model-invoked

The `tdd` and `code-review` skills remain model-invoked so `implement` can apply both without human routing and AFK tickets still receive their agreed test and review disciplines. `handoff` becomes user-invoked because only a human starts it, while the new user-invoked `solve` flow makes intentionally skipping TDD and review visible rather than allowing either discipline to disappear silently.

## Considered Options

- Make `tdd` and `code-review` user-invoked: lowers permanent context load but prevents `implement` from reaching them autonomously.
- Let `implement` skip either discipline opportunistically: avoids another flow but hides the omission in agent judgment.
- Add an explicit `solve` flow: increases the user-invoked inventory but makes the trade-off deliberate and auditable in the transcript.
