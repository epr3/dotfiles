# Artifact locations

Destinations for the durable artifact classes, recorded once per repo by `setup-context` and resolved per class by every skill that reads or writes them. One line per class; a line absent means the default, which equals the destination each class already had.

- `code` -- the code repo's worktree (the repo root under in-repo context)
- `context` -- the context worktree, or the code repo root under in-repo context (the **context home**)
- `custom:<path>` -- an explicit directory; `{branch}` resolves to the current code branch, and if the path lacks it, `/<branch>` is appended so a **context repo**'s branches never mix their outputs (identical branch-local artifact names stay separate)

Resolve with `<setup-context skill dir>/resolve-location.sh <class>` run with cwd in the code repo. This repo is **in-repo context**, so every class's default and every recorded line below resolves to the code repo root; glossary discovery reads `GLOSSARY.md` / `GLOSSARY-MAP.md` only. This file sits in the **config home** (`docs/agents/`): repo-wide rules, branch-independent. Temporary reports and handoffs are not recorded here; they use the OS temp directory.

## Locations

glossary: context
adrs: context
board: context
research: context
explainers: context
