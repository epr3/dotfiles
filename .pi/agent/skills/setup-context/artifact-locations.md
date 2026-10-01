# Artifact locations

Destinations for the durable artifact classes, recorded once per repo by `setup-context` and resolved per class by every skill that reads or writes them. One line per class; a line absent means the default, which **equals the destination each class already had**, so an existing setup needs no reconfiguration to keep working.

- `code` -- the code repo's worktree (the repo root under in-repo context)
- `context` -- the context worktree, or the code repo root under in-repo context (the **context home**)
- `custom:<path>` -- an explicit directory; `{branch}` resolves to the current code branch, and if the path lacks it, `/<branch>` is appended so a **context repo**'s branches never mix their outputs (identical branch-local artifact names stay separate)

Resolve with `<setup-context skill dir>/resolve-location.sh <class>` run with cwd in the code repo. Classes: `glossary`, `adrs`, `board`, `research`, `explainers` (the board's `.scratch/` and explainers' `explainers/` subpaths are the consumers'). This file sits in the **config home**: repo-wide rules, branch-independent by construction. Temporary reports and handoffs are **not** recorded here; they use the OS temp directory.

## Locations

glossary: %GLOSSARY%
adrs: %ADRS%
board: %BOARD%
research: %RESEARCH%
explainers: %EXPLAINERS%
