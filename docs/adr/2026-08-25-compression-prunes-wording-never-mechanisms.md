# Compression prunes wording, never mechanisms

When selectively porting upstream skills, compression may remove repetition and stylistic expansion but must preserve every behavioral mechanism and branch. Removing a mechanism requires its own explicit ADR; otherwise a shorter document can silently change behavior in later sessions, where the loss is difficult to diagnose.

## Considered Options

- Copy upstream prose wholesale: preserves mechanisms but discards the suite's Pi-specific voice and local context-store adaptations.
- Compress both prose and behavior: produces the smallest files but makes mechanism loss accidental and invisible.
- Compress wording only: keeps the local suite concise while making behavioral divergence deliberate and reviewable.
