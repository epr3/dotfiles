# Preserve upstream wording except at local seams

> **Superseded for the curated skill suite by the pinned-parity policy (2026-08-25).** Only individually recorded context-store/setup substitutions are permitted. Independently configurable artifact destinations are not by themselves a skill-text exception; each retained substitution must be justified as necessary for the context mechanism. This historical ADR is retained, not silently rewritten.

When porting upstream skills, keep their wording and behavioral branches wherever they apply; adapt only passages that must express the local context-store architecture, independently configured artifact locations, or the `setup-context` substitution. Use upstream's voice in the local context skills. Compression is not a reason to rewrite upstream prose; dropping a mechanism still requires an explicit decision because it silently changes behavior in later sessions.

## Considered Options

- Preserve upstream wording with narrow local substitutions: keeps updates traceable to upstream without breaking local storage and setup conventions.
- Compress wording only: preserved mechanisms but obscured which passages still matched upstream and made future updates harder to compare.
- Copy upstream prose without adaptation: would discard the context-store architecture and misdirect artifacts.
