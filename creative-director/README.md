# creative-director

Turns Claude into the **creative director of an award-winning interactive agency** (Lusion /
Dogstudio / Make Me Pulse / Active Theory caliber). Instead of generating a website on
request, it *runs the creative process*: interviews you, challenges weak answers, gates on
approval at each milestone, then orchestrates specialist roles to produce a **Creative Brief**
and an **Engineering Brief** another coding agent can build from.

## Why it's built this way

Those studios aren't impressive because of one CSS trick — they combine creative direction,
motion systems, WebGL, type, sound, and ruthless performance work. The bottleneck isn't
knowing the libraries (modern agents know Three.js/R3F/GSAP/Lenis/shaders); it's *direction*.
So this skill's job is to extract a sharp brief and specify intent precisely, not to dump
code.

## Architecture — orchestrator + specialists

`creative-director` is the single installed skill (the entry point). It dispatches specialist
**roles** as subagents — it doesn't install them as separate skills, which would clutter the
global skill list and mis-trigger. Each role is a brief in `references/specialists/`; improve
or swap any one without touching the rest.

```
creative-director/
├── SKILL.md                          # the orchestrator: pipeline, gates, behaviors
└── references/
    ├── discovery-interview.md        # agency-grade question bank + challenge patterns
    ├── brief-and-concepts.md         # Creative Brief / Concepts / Storyboard templates
    ├── engineering-brief-template.md # the buildable handoff document
    └── specialists/
        ├── brand-strategist.md
        ├── experience-strategist.md
        ├── art-director.md
        ├── copywriter.md
        ├── motion-director.md
        ├── 3d-director.md
        └── frontend-architect.md
```

## The pipeline

```
Discovery → Creative Brief [gate] → Concepts [gate] → Storyboard [gate]
→ Motion Direction → Visual Direction → Engineering Brief [gate]
```

Output lands in a `creative-direction/` folder in your project (`01-creative-brief.md` …
`06-engineering-brief.md`). The engineering brief is the payload — hand it to
`build-ui-from-design` or a senior engineer to build.

## Use it

Invoke by name (`/creative-director`) or just describe wanting a premium / cinematic /
immersive / Awwwards-style experience — the description triggers it. It will interview you
before designing anything; that's the point.
