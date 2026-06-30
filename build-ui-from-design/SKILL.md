---
name: build-ui-from-design
description: Build a UI screen or component pixel-perfect from any design source — the platform-agnostic method. Get the real design spec (don't eyeball), map every value to design-system tokens, build the real element structure, then verify by actively bug-hunting the rendered result against the source. Use when the user provides a design reference and asks to build, implement, match, or make a screen "pixel-perfect". For tool specifics, pair with build-ui-from-figma or build-ui-from-stitch.
---

# Build UI from a design source (core method)

The method that's true regardless of design tool or framework. Platform-specific
fetching lives in the adapter skills (`build-ui-from-figma`, `build-ui-from-stitch`); the
discipline below does not change. If the project has its own UI-build skill or
conventions (e.g. a project-specific `CLAUDE.md`), those take precedence — this
layers on top.

See also the repo's `AGENTS.md`: "Verify, don't confirm" and "No raw hex — use tokens".

---

## Step 0 — Creative Brief gate (hard requirement)

Before touching any design spec or writing any code, confirm an approved Creative Brief
exists for this feature.

**Brief exists** (in the conversation, a `.creative-brief.md` in the project root, or an
approved output from a prior `/creative-director` run): summarise the key creative intent
in one sentence, then proceed. Keep it in view while building — it is the north star, not
the Figma file.

**No brief**: stop here. Do not eyeball the design and "just build it." Say:
> "There's no Creative Brief for this feature. A brief is required before building so the
> output has creative intent, not just correct pixels. Running `/creative-director` now."

Then invoke `/creative-director` and wait for the brief to be approved before continuing
to Step 1. This is the gate that separates distinctive products from generic SaaS clones.

---

## Step 1 — Get the REAL design spec, don't eyeball
A screenshot hides exact radius, padding, fill, borders, focus/hover/error states, and
whether a control is one element or several joined ones. Get the underlying spec via the
right adapter:
- **Figma** → `build-ui-from-figma` (Figma MCP `get_design_context`).
- **Google Stitch** → `build-ui-from-stitch` (fetch the screen's HTML export, read its classes).
- **Other tool with inspect/export** → read the inspected CSS or exported markup.
- **Only a screenshot exists** → say so explicitly, extract what you can, and flag that
  exact values are estimated and need confirmation.

Capture per element: structure (one control or joined parts?), colors, typography
(size/weight/line-height), spacing (padding/gap/radius), and every interactive state
visible across frames (empty / filled / focus / error / disabled / open). When multiple
frames are the same screen in different states, name the pattern (empty / filled / error).

## Step 2 — Map every value to design tokens
Read the project's token source (CSS `@theme`/`:root`, a `theme.ts`/`colors` module,
Tailwind config). For each value in the design:
1. Exact or semantically equivalent token exists → use it.
2. Missing → add it to the token source first, under the right semantic group, then
   reference it.
Never hardcode raw hex/rgb in components. Gradients/shadows without a token go in `:root`
as custom properties, referenced by variable.

## Step 3 — Build the REAL structure
Reproduce the actual element structure, not an approximation. If the design shows a joined
control (a country-code prefix fused to a phone input, an input group with an addon, a
segmented control), build it as joined parts that share a seam and **align exactly** — not
a single field with a label hack. Match radius, padding, fill, border, and every state
(focus/hover/error/disabled) to the Step 1 spec.

## Step 4 — Render it
Get it running so you can see real pixels (dev server / hot reload / preview). For
canvas-based renderers (e.g. Flutter web) the DOM won't reflect the widgets — screenshot
the rendered output and hard-reload to clear stale bundles before judging.

## Step 5 — VERIFY = bug-hunt, not confirm
The step that's easy to fake. Treat the screenshot as a defect hunt — look for what's
WRONG before declaring it right:
- Edge/border alignment between adjacent elements — equal heights, shared seams, no overhang
- Text baselines and vertical centering
- Spacing/padding symmetry; unexpected gaps, clipping, overflow, truncation
- Radius, fill, border color/width vs spec
- Focus / hover / error / disabled states actually styled
- Contrast and legibility
- **Side-by-side against the design source**, not from memory

Zoom into joins and small controls specifically — that's where misalignment hides. Only
after this hunt, with deltas fixed, report done. Note what a screenshot can't prove
(keyboard overlap, focus traps, device behavior) and cover those with the app/tests.

## Step 6 — Keep the suite green
If components changed shape (label casing, a field split into two, a widget became
stateful), update affected assertions to match the new correct design and run the suite
green. Remove dead/boilerplate tests rather than leaving the suite red.
