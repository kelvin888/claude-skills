---
name: build-ui-figma
description: Build a UI screen pixel-perfect from one or more Figma frames. Fetches all frames via the Figma MCP, extracts colors/typography/spacing/assets/states, downloads icon assets, then follows the build-ui-from-design method. Use when the user provides Figma URLs and asks to build, implement, or match a screen. For the full TradeAxis Next.js stack specifically, use tradeaxis-build-ui instead.
---

# Build UI from Figma

Figma adapter for the `build-ui-from-design` core method. Covers getting the real spec out
of Figma; the build/verify discipline is in `build-ui-from-design` and `AGENTS.md`. For a
project with a heavy established stack (BFF, data layer), prefer that project's own skill
(e.g. `tradeaxis-build-ui`) which layers concrete file conventions on top of this.

---

## Step 1 — Fetch all frames in parallel
Call `mcp__figma__get_design_context` for every URL the user gave, in one parallel batch —
never sequentially. Extract from each frame:
- **What it represents**: which screen/step/state (empty / filled / error / loading /
  dropdown-open). If several frames are the same screen in different states, name the
  pattern — it drives how you build the component.
- **Colors** used anywhere in the frame
- **Typography**: font size, weight, line-height
- **Spacing**: padding, gap, border-radius
- **Assets**: Figma CDN URLs in the `const imgXxx = "..."` lines
- **Interactive states** visible across frames

## Step 2 — Download icon/image assets
For each `const imgXxx = "https://www.figma.com/api/mcp/asset/..."` the component needs:

```bash
curl -sL "<figma-cdn-url>" -o <assets-dir>/<name>.svg
file <assets-dir>/<name>.svg   # confirm SVG; rename if actually PNG
```

Only download assets new to this feature — reuse existing shell/nav icons. Store under the
project's asset convention.

## Step 3 — Map tokens & build (core method)
Hand off to `build-ui-from-design` Steps 2–3: map every Figma color/shadow/gradient to a
design token (add missing ones), and build the real element structure.

**Figma emits arbitrary values — convert to canonical scale.** Figma output also uses
absolute positioning and grid hacks; rewrite with semantic flexbox/grid. Example
conversions (project-dependent, confirm against the theme):

| Figma arbitrary | Canonical |
|---|---|
| `size-[108px]` | `size-27` |
| `px-[17px]` | `px-4.25` |
| `py-[13px]` | `py-3.25` |
| `gap-[9px]` | `gap-2.25` |
| `max-w-[1280px]` | `max-w-7xl` |

## Step 4 — Render & verify
Per `build-ui-from-design` Steps 4–6: render, bug-hunt the result side-by-side against the
frames (zoom into joins and small controls), cover all states the frames define, and keep
the test suite green.

## Prerequisite
The Figma MCP tool (`mcp__figma__get_design_context`) must be available in the session,
otherwise Step 1 can't fetch frames.
