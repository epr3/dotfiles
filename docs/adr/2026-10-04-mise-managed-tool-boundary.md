# Give mise ownership of standalone developer tools

For Apple Silicon macOS, mise will own supported standalone developer runtimes and CLIs, with committed global configuration and lockfiles so fresh-machine setup reproduces reviewed versions rather than silently upgrading. Homebrew remains responsible for mise itself, foundational Git and shells, OS dependencies, GUI applications, and explicit exceptions where mise is unsuitable; editor-managed plugins and language servers, shell plugins, agent CLIs (Pi, OpenCode, and Claude Code), and Dotbot remain outside the migration. This favors reproducibility and clear ownership over forcing every installation through one manager, and preserves the Dotbot boundary in [the guarded bootstrap decision](2026-07-18-curated-tool-config-bootstrap.md).

Trusted project configuration may override the global defaults, including compatible existing runtime-version files, without rewriting other repositories. Project trust and missing-tool installation require explicit action; directory changes select installed versions without triggering downloads. Migration preserves existing supported runtime versions, selecting and locking supported stable releases only where no runtime is installed, and does not automatically uninstall previous tools or delete their runtime state; cleanup follows verification and explicit human approval. Existing package-manager paths required by excluded agent CLIs must remain usable.

Flutter retains its custom Flutter-Foundation source, with a pinned revision instead of floating master; it remains an explicit exception if mise cannot reproduce that setup. The initial revision must be established from the existing checkout where available; otherwise it needs explicit review before installation.

If an existing runtime version or Flutter revision cannot be reproduced, implementation stops for a human decision rather than silently upgrading or switching sources.

Managed tools must be accessible in interactive terminals, noninteractive Zsh scripts, and GUI-launched editors. Use interactive shell activation, stable shims for noninteractive and editor access, and explicit mise execution in bootstrap stages; GUI launch environments must be verified rather than assumed to inherit shell startup files.

Amended 2026-10-04: Claude Code was removed from the machine with explicit human approval — no binary existed (see the migration inventory's decision D7). It is no longer a retained agent CLI; the exclusion above stands for Pi and OpenCode.
