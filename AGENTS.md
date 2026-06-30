# Agent working habits

Tool-agnostic principles for any coding agent. Claude Code reads `CLAUDE.md`; you can
point it here with a one-line `CLAUDE.md` that says `@AGENTS.md` (import), or copy the
sections you want. Other agent tools can read this file directly.

## Verify, don't confirm
When you say you'll "verify" UI or any visible output, that means an active **bug hunt**,
not a presence check. Before declaring anything correct, scan for what's WRONG: edge and
border alignment between adjacent elements, equal heights and shared seams, text baselines
and vertical centering, spacing/padding symmetry, unexpected gaps or overhang,
overflow/clipping/truncation, contrast and legibility, and correctness against the design —
compared side by side, not from memory. Zoom into joins and small controls specifically.
"It rendered and looks about right" is not verification. Be honest about what a screenshot
cannot prove (keyboard overlap, focus traps, real-device behavior) and cover those with
the running app or tests.

## No raw hex — use design tokens
Never hardcode color values (hex/rgb) in component or style code. Always reference the
project's design-system tokens (CSS variables, a theme/colors module, Tailwind theme).
If a needed color/shadow/gradient has no token, add it to the token source first under the
right semantic group, then reference it. The same applies to user-facing copy where the
project centralizes strings.

## Read the real source, don't eyeball
When reproducing a design, a spec, or an API, work from the authoritative source (the
design tool's real markup/tokens, the actual schema, the actual error output) — not from a
screenshot, a guess, or memory. Eyeballing is how exact radius, padding, joined-control
structure, and edge cases get missed.

## Keep the suite green
If a change alters component shape (label casing, a field split in two, a widget becoming
stateful), update the affected test assertions to match the new correct behavior and run
the suite green before finishing. Remove dead/boilerplate tests you encounter rather than
leaving the suite red.

## Creative direction before any UI work
Never build a UI feature without an approved Creative Brief. When any design or UI task
arrives — whether or not the user uses those words — check whether a Creative Brief exists
(in the conversation or as a `.creative-brief.md` in the project).
- **No brief exists**: do not proceed to implementation. Invoke `/creative-director` and
  wait for the brief to be approved before writing a single line of component code.
- **Brief exists**: reference it during the build to ensure the implementation reflects
  the creative intent, not just the pixel values.
"It matches the Figma/Stitch" is not done — it must also reflect the approved creative
direction. Pixel-perfect on a mediocre design is still a mediocre product.

## Follow the feature workflow for all new work
Every new feature and every new project must pass through the full pipeline before
implementation begins: creative direction (if UI) → spec → stress test → issues →
implement → review → deploy. Skipping phases is not a shortcut — it is the source of
generic output and rework. If someone asks you to "just build it", ask for the spec first.
Reference `/feature-workflow` for the complete gate sequence.
