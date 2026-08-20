# Adopt the 200k Dumb-zone contract in the deployed Pi statusline

The dotfile-managed Pi statusline override (`~/.pi/agent/settings.json`, mirrored as `.pi/agent/settings.json`) will use an **effective limit** of 200,000 tokens with sharp, fading, and risky thresholds at equal thirds of that limit. The **Caveman boundary** is inclusive: an agent at or over the effective limit is `caveman`, so exactly 200,000 tokens classifies as caveman rather than risky. The existing small-model clamp and environment/project/user override precedence are unchanged. The statusline package default moved with this contract in `pi-extensions` (statusline 0001); this repository adopts the verified contract so the deployed override and the shipped default cannot drift.

## Considered Options

- Keep the 120k contract: rejected because the verified package default and its tests, documentation, and shipped `packages/pi-config/settings.json` now describe a 200k inclusive boundary; retaining 120k here would reintroduce configuration drift.
- Stagger stops at rounded token constants: rejected — the machine configuration keeps the fractional third thresholds and lets the effective limit scale them, matching the spec's decision.
- Exclusive boundary (>limit = caveman): rejected — prose now matches classification: caveman begins at or over the effective limit.