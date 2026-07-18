# UI Prototype

**Several radically different UI variants** on one route, switched from a floating bottom bar. User flips in the browser, picks one (or steals bits from each), throws the rest away. Logic/state question → wrong branch, [LOGIC.md](LOGIC.md).

Right shape for: "what should this page look like", "see a few options before committing", "try a different layout".

## Two sub-shapes — strongly prefer A

Variants are easiest to judge **butting up against the real app** — real header, real data, real density. A route in a vacuum makes every variant look fine.

- **A — adjustment to an existing page (default).** Same route, variants gated by `?variant=`; existing data fetching/params/auth stay, only the rendering swaps. New thing that *naturally lives inside* an existing page (new dashboard section, new settings card, new flow step) → still A: mount inside the host page.
- **B — new page (last resort).** Only when there's genuinely no host page (entirely new surface, or a flow that can't be embedded anywhere sensible). Throwaway route per the project's routing convention — don't invent a new top-level structure — `prototype` in the path/filename, same `?variant=`. Sanity-check first: an empty route hides design problems a populated one exposes.

## Process

1. **State the question, pick N.** Default **3 variants**, cap 5 (beyond that = noise). One-line plan in a top-of-file comment: "Three variants of settings, `?variant=`, on existing `/settings`."
2. **Generate radically different variants.** Each holds to: the page's purpose and available data; the project's component/styling system; a clear export (`VariantA`…). **Structurally** different — layout, information hierarchy, primary affordance — not colours. Two drafts too similar → redo one with explicit "no card grid"-style constraints. If the `Agent` tool is available, spawn one `general` sub-agent per variant in parallel (`run_in_background: true`, collect via `get_subagent_result`), each briefed with a different structural constraint — cf. [codebase-design's design-it-twice](../codebase-design/DESIGN-IT-TWICE.md); else generate sequentially.
3. **Wire a single switcher** on the route:

   ```tsx
   const variant = searchParams.get('variant') ?? 'A';
   return (<>
     {variant === 'A' && <VariantA {...data} />}
     {variant === 'B' && <VariantB {...data} />}
     {variant === 'C' && <VariantC {...data} />}
     <PrototypeSwitcher variants={['A','B','C']} current={variant} />
   </>);
   ```

   Sub-shape A: existing data fetching stays above the switcher. Sub-shape B: throwaway route mounts the same switcher.
4. **Floating switcher**: fixed bottom-centre pill — ← prev (wraps) · `B — Sidebar layout` label · → next. Arrows update the URL param via the framework's router (shareable, reload-stable); `←`/`→` keys also cycle, except when an input/textarea/contenteditable is focused. Visually distinct from the design under evaluation. **Hidden in production** (`NODE_ENV !== 'production'` gate) so a stray merge can't ship it. One shared component, located with the project's shared UI.
5. **Hand it over** — surface the URL and variant keys. The gold feedback is "header from B with the sidebar from C" — that's the actual design.
6. **Capture + clean up.** Record which variant won and why (commit/ADR/issue, or `NOTES.md` if AFK). A: delete losers + switcher, fold winner in. B: promote winner to a real route, delete the throwaway. Don't leave variants rotting.

## Anti-patterns

- **Colour/copy-only variants** — that's a tweak. Real variants disagree about structure.
- **Sharing too much** — shared `<Header>` fine; shared `<Layout>` defeats the point.
- **Real mutations** — read-only or stubs; the question is looks, not backend.
- **Promoting prototype code to production** — it was written under prototype constraints; rewrite when folding in.
