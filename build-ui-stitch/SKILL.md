---
name: build-ui-stitch
description: Build a UI screen pixel-perfect from a Google Stitch design. Identifies the right Stitch project/board, fetches the screen's real HTML export, reads the actual Tailwind classes + theme tokens (never eyeballs the screenshot), then follows the build-ui-from-design method. Use when the user references a Stitch design/board/screen and asks to build, implement, or match a screen.
---

# Build UI from Google Stitch

Stitch adapter for the `build-ui-from-design` core method. Stitch generates HTML with
Tailwind classes and an embedded theme config — the exact spec is in that markup, NOT in
the screenshot. This skill covers getting it; the build/verify discipline is in
`build-ui-from-design` and `AGENTS.md`.

---

## Step 0 — Creative Brief gate (hard requirement)

Before fetching any Stitch screen or writing any code, confirm an approved Creative Brief
exists for this feature.

**Brief exists** (in the conversation, a `.creative-brief.md` in the project root, or a
prior `/creative-director` run): note the key creative intent, then proceed to Step 1.

**No brief**: stop. Do not proceed. Say:
> "There's no Creative Brief for this feature. A brief is required before building so the
> output has creative intent, not just correct pixels. Running `/creative-director` now."

Invoke `/creative-director` and wait for approval before continuing.

---

## Step 1 — Find the right project and board
Stitch accounts often have many projects, several titled similarly. Confirm which board
is the source of truth before fetching:
- `mcp__stitch__list_projects` → if the result is large it's saved to a file; extract
  ids/titles with `jq`.
- A product usually spans multiple boards (e.g. older + newer screens, or
  customer vs admin) with **no conflict** — different boards cover different screens.
  Don't assume one is "the wrong one"; ask the user which board owns the screen if unsure,
  and record the board→purpose mapping so you don't re-derive it next session.
- `mcp__stitch__list_screens <projectId>` → find the screen by title.

## Step 2 — Fetch the REAL HTML export (don't eyeball)
Each screen in `list_screens` has `htmlCode.downloadUrl`. Download it and read the markup:

```bash
curl -sL "<htmlCode.downloadUrl>" -o /tmp/screen.html
file /tmp/screen.html   # confirm it's HTML, not a 404/asset
```

Then extract the real spec, not from the picture:
- Input/button/control markup: `grep -oE '<input[^>]*>|<button[^>]*>' /tmp/screen.html`
- The theme tokens: Stitch embeds a Tailwind config — grep for the color map,
  `borderRadius`, and any `<style>` rules (e.g. `.foo:focus { ... }`) for focus/hover.
- Note joined controls: a phone field is often a `+234` prefix box (`rounded-l-*`,
  tinted bg) fused to the number input (`rounded-r-*`) — build it as two joined parts.
- Note label patterns: Stitch often uses a label ABOVE the field (not a floating label)
  that changes color on focus.

## Step 3 — Map tokens, build the real structure
Hand off to `build-ui-from-design` Steps 2–3. Map Stitch's hex values to the project's
design tokens (add missing ones, e.g. a muted placeholder color). Reproduce joined
controls so both halves share a seam and align exactly.

## Step 4 — Render & verify (Stitch screenshots LIE about detail)
Stitch's preview image is downsampled and bakes in chrome — never treat "looks like the
preview" as done. Render the real app and **bug-hunt** per `build-ui-from-design` Step 5.
For Flutter web (canvas), the DOM is opaque to inspectors: drive and screenshot via a
browser-control tool, hard-reload (`cmd+shift+r`) to clear the stale bundle, and **zoom
into joins** — that's where defects hide (a prefix box taller than its field, a seam that
doesn't meet).

## Hard-won lessons
- The onboarding/hero images in a Stitch screen are real `<img src>` assets in the HTML —
  download those, don't screenshot the whole rendered screen as a "background".
- A two-part control built with `CrossAxisAlignment.stretch` (Flutter) needs an
  `IntrinsicHeight` wrapper, and let the text field define the height so the prefix
  matches it — otherwise the prefix overhangs.
- Record the board→purpose map and any token equivalences as project memory; you will
  need them every time you touch another screen on the same product.
