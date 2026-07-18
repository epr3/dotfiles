# HTML Report Format

Single self-contained HTML in OS temp dir. Tailwind + Mermaid via CDN. Mix Mermaid (graph-shaped: call graphs, sequences) with hand-built divs/inline SVG (editorial: mass diagrams, cross-sections). Don't lean on Mermaid for everything — it looks generic.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review — {{repo}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

Repo name + date + compact legend: solid box = module, dashed line = seam, red arrow = leakage, thick dark box = deep module. No intro paragraph.

## Candidate card

Diagrams carry the weight. Prose sparse. Glossary terms ([codebase-design](../codebase-design/SKILL.md)) without ceremony.

Each candidate is one `<article>`:

- **Title** — short, names the deepening ("Collapse the Order intake pipeline")
- **Badge row** — strength (`Strong` emerald / `Worth exploring` amber / `Speculative` slate) + dependency category tag (`in-process` / `local-substitutable` / `ports & adapters` / `mock`)
- **Files** — `font-mono text-sm`
- **Before/After diagram** — two columns, side by side. Centrepiece.
- **Problem** — one sentence
- **Solution** — one sentence
- **Wins** — bullets ≤6 words: "Tests hit one interface", "Pricing stops leaking", "Delete 4 wrappers"
- **ADR callout** (if applicable) — one line, amber-tinted box

If a diagram needs a paragraph to be understood, redraw it.

## Diagram patterns — pick one, mix them

**Mermaid graph** — workhorse for dependencies/call flow. `flowchart` or sequence. Style with `classDef` (red leakage, dark deep module).

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

**Hand-built boxes-and-arrows** — when Mermaid's layout fights you. Modules as `<div>` with borders. Arrows as inline `<svg>` `<line>`/`<path>` over a relative container. Use for "after" diagrams with one thick-bordered deep module + greyed internals.

**Cross-section** — layered shallowness. Stack horizontal bands (`h-12 border-l-4`). Before: 6 thin layers doing nothing. After: 1 thick band, consolidated responsibility.

**Mass diagram** — interface vs implementation surface area. Two rectangles per module. Before: interface ≈ implementation (shallow). After: short interface, tall implementation (deep).

**Call-graph collapse** — before: nested-box tree. After: one box, faded internal calls inside.

## Style

- Editorial, not corporate-dashboard. Generous whitespace. `font-serif` optional for headings.
- Colour: one accent (emerald or indigo) + red for leakage + amber for warnings.
- Diagrams ~320px tall for side-by-side fit.
- Module labels: `text-xs uppercase tracking-wider` — schematic, not UI.
- Static. No app code. Only scripts: Tailwind CDN + Mermaid ESM.

## Top recommendation

One larger card. Candidate name, one sentence, anchor link.

## Tone

Plain English, concise. Architectural nouns and verbs from [codebase-design](../codebase-design/SKILL.md).

**Use exactly:** module, interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality.

**Never substitute:** component/service/unit (for module) · API/signature (for interface) · boundary (for seam) · layer/wrapper (for module).

**Phrasings:**
- "Order intake module is shallow — interface nearly matches implementation."
- "Pricing leaks across the seam."
- "Deepen: one interface, one place to test."
- "Two adapters justify the seam: HTTP in prod, in-memory in tests."

**Wins** name the gain: *"locality: bugs concentrate"*, *"leverage: one interface, N call sites"*, *"interface shrinks; implementation absorbs the wrappers"*. Not *"easier to maintain"* or *"cleaner code"*.

No hedging. No throat-clearing. No "it's worth noting that…". If a sentence could be a bullet, make it a bullet. If a bullet could be cut, cut it.
