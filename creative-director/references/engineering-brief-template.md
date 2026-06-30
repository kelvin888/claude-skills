# Engineering Brief — handoff template

This is the payload. It's what a senior React engineer or another coding agent (e.g. via
`build-ui-from-design`) builds the experience from. It must be precise enough that the build
is unambiguous, and honest enough about performance that it's actually shippable. The
**Frontend Architect** specialist owns this; the director approves it as the build contract.

Write to `creative-direction/06-engineering-brief.md`.

```markdown
# Engineering Brief — [Project]

## 1. Concept & feeling (one paragraph)
The single idea and the dominant feeling, so every technical decision has a north star.

## 2. Recommended stack
State choices with reasons; don't list every library that exists. Typical baseline:
- **Framework** — Next.js (App Router) / React. Why.
- **3D** — Three.js via React-Three-Fiber + drei. Only if the concept is 3D.
- **Animation** — GSAP (+ ScrollTrigger) for scroll/timeline; Framer Motion for component
  state/page transitions. State which does what so they don't fight.
- **Smooth scroll** — Lenis, synced to ScrollTrigger.
- **Shaders** — raw GLSL where a stock material won't do; name the effect.
- **Other** — Lottie / SVG / video textures / particles / physics — only what the concept needs.

## 3. Motion architecture
- How scroll is driven (Lenis → ScrollTrigger; single scroll timeline vs. per-section).
- Where the camera lives and how it moves (one continuous rig vs. per-scene cuts).
- The reduced-motion strategy: what degrades, and to what. (Not optional.)

## 4. Component & scene structure
A tree mapping each storyboard scene to components. Note which are R3F (canvas) vs. DOM, and
how DOM overlays register against the 3D scene.

## 5. Folder structure
A concrete proposed layout (scenes/, components/, shaders/, hooks/, lib/, etc.).

## 6. Design tokens
Colors, type scale, spacing, easing curves, and timing as **tokens** (CSS variables /
theme module) — never raw hex in components (see repo AGENTS.md "No raw hex"). List the
named easing curves and standard durations so motion is consistent across the build.

## 7. Performance strategy
The make-or-break section. Budget targets (FPS, bundle, draw calls), asset strategy
(compression, KTX2/Draco, lazy-loading off-screen scenes), instancing for particles,
when to drop to a lighter path on weak GPUs / mobile, and how the loading experience itself
is designed (not a spinner — part of the show).

## 8. Accessibility
Reduced-motion path, keyboard navigation through a scroll-jacked experience, focus order,
semantic DOM under the canvas, captions for any sound, contrast on text over moving
backgrounds.

## 9. Scene-by-scene implementation map
For each storyboard scene, the concrete build notes: the motion (from Motion Direction), the
visuals/3D (from Visual Direction), the trigger points, and the assets required. This is the
section the engineer reads while building scene N.

## 10. Open questions & risks
What still needs a decision, asset, or spike before/while building.
```

Keep it buildable. Ambition that ignores the performance and accessibility sections isn't
direction — it's a wishlist. The director's signature on this brief means it's both
inspiring *and* shippable.
