# No maintained dotfiles test suite

This repository keeps configuration rather than a maintained test suite: remove repository test files and test-only tooling across all configurations, including OpenCode. Repository-owned verification scripts and parity exception records are also retired (2026-10-08); Pi and OpenCode assets are maintained independently, without upstream lockstep. Lightweight ad hoc configuration checks such as JSON parsing, shell syntax checks, and reference checks remain allowed; testing skills and instructions for work in other projects remain intact.

This is a standing policy, not a one-time cleanup. Active documentation must reflect it, while historical tickets and records of checks previously run are preserved. The trade-off is losing automated regression coverage in exchange for a smaller configuration-maintenance surface; existing runtime behavior contracts remain unchanged.
