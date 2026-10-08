# Preserve upstream wording except at local seams

> **Historical.** Superseded for the curated skill suite by the pinned-parity policy (2026-08-25), which restricted changes to individually justified context-store/setup substitutions. That policy was retired on 2026-10-08; skill copies are now maintained independently. The body below records the earlier decision, not a current restriction on skill edits.

When porting upstream skills, keep their wording and behavioral branches wherever they apply; adapt only passages that must express the local context-store architecture, independently configured artifact locations, or the `setup-context` substitution. Use upstream's voice in the local context skills. Compression is not a reason to rewrite upstream prose; dropping a mechanism still requires an explicit decision because it silently changes behavior in later sessions.

## Considered Options

- Preserve upstream wording with narrow local substitutions: keeps updates traceable to upstream without breaking local storage and setup conventions.
- Compress wording only: preserved mechanisms but obscured which passages still matched upstream and made future updates harder to compare.
- Copy upstream prose without adaptation: would discard the context-store architecture and misdirect artifacts.
