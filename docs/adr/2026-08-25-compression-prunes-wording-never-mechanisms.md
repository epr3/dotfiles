# Preserve upstream wording except at local seams

When porting upstream skills, keep their wording and behavioral branches wherever they apply; adapt only passages that must express the local context-store architecture, independently configured artifact locations, or the `setup-context` substitution. Use upstream's voice in the local context skills. Compression is not a reason to rewrite upstream prose; dropping a mechanism still requires an explicit decision because it silently changes behavior in later sessions.

## Considered Options

- Preserve upstream wording with narrow local substitutions: keeps updates traceable to upstream without breaking local storage and setup conventions.
- Compress wording only: preserved mechanisms but obscured which passages still matched upstream and made future updates harder to compare.
- Copy upstream prose without adaptation: would discard the context-store architecture and misdirect artifacts.
