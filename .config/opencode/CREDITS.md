# Credits and third-party attribution

This directory holds independently copied, non-secret agent assets for OpenCode v2. Nothing here is symlinked back to Pi, and no runtime dependency on the Pi source tree is implied. The files below carry attribution beyond this repository's own MIT `LICENSE.md`.

## Skill suite

Most skills under `skills/` are adapted copies of the curated suite at [github.com/mattpocock/skills](https://github.com/mattpocock/skills) (MIT, Copyright (c) 2026 Matt Pocock), pinned in `scripts/parity/map.sh` and recorded in the root `GLOSSARY.md` under **Upstream**. Remaining skills are local-only workflows owned by this repository. The Pi copies under `.pi/agent/skills/` are the wording source; the OpenCode copies are independent and may diverge.

Per-skill attribution that travels with the prose lives beside it, for example [`skills/pr/CREDITS.md`](./skills/pr/CREDITS.md), which credits Dex Horthy's `show-me` for the visual menu reproduced in the `pr` skill.

## Theme material

No Pi theme file is copied. OpenCode ships the Catppuccin variants the setup selects (`cli.json` → `catppuccin`) and exposes resolved theme tokens to CLI plugins, so the footer adapter consumes OpenCode's own theme rather than a copied palette. Pi theme files remain unmodified in `.pi/agent/themes/`.

## Host-API prior art

The dumb-zone footer plugin (`.config/opencode/plugins/dumb-zone/`) is this repository's own implementation of the deployed Dumb-zone contract (see `docs/adr/2026-08-20-dumb-zone-contract-200k.md`); its pure zone and segment modules are independent code with no imports from Pi or from any external package. The OpenCode v2 CLI-plugin host-API patterns it follows — the TUI entry layout, the `prompt.footer.status` slot claim, the event set and session-record reads, and the teardown/hot-reload discipline — were adapted from the MIT-licensed [github.com/rashidrazak/opencode-status-line](https://github.com/rashidrazak/opencode-status-line) (Copyright (c) rashidrazak) documentation and prior art, and were re-verified against the installed v2.0.22 release.

## Not copied

Pi runtime extensions and external Pi extension packages are not copied or loaded as OpenCode plugins. See `docs/opencode-v2-asset-inventory.md` for the disposition of each (native equivalent, later ticket, or unsupported).
