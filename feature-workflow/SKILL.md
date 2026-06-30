---
name: feature-workflow
description: The master workflow for building any new feature or new project. Enforces a sequential pipeline — creative direction → spec → stress test → issues → implement → review → deploy — so nothing ships without passing every quality gate. Use when starting a new project, starting a new feature, when someone says "let's build X", "we need a feature for Y", "new project", or when anyone is about to jump straight to implementation without a spec or brief. Also trigger when a team member asks how to approach new work.
---

# Feature Workflow

The pipeline that separates products built with intention from ones assembled in a hurry.
Every new feature and every new project follows these phases in order. Each phase has a
required output — the gate to the next phase. No skipping.

---

## Start here: project or feature?

**New project** — nothing exists yet, greenfield or near-greenfield.
Follow all 7 phases below.

**New feature on an existing project** — codebase exists, adding new capability.
Skip Phase 1 (architecture is already set) unless the feature requires a new module or
service. Start at Phase 2.

---

## Phase 1 — Foundation (new projects only)

Before any product work, the technical foundation must be agreed.

**Questions to answer:**
- What problem does this product solve, and for whom?
- What is the tech stack? (Read any existing CLAUDE.md/agents.md, or decide now)
- What are the top-level modules / bounded contexts?
- What are the non-negotiables? (auth, multi-tenancy, compliance, uptime)

**Gate — output required before Phase 2:**
> `architecture-brief.md` — one page covering stack, module map, top-level constraints,
> and the single most important technical decision and why.

If no CLAUDE.md/agents.md exists yet, create one now. The next feature won't need to
re-derive what the project already uses.

---

## Phase 2 — Creative Direction (required if any UI is involved)

**Invoke: `/creative-director`**

Do not design or build UI until a Creative Brief is approved. This is the gate that
prevents generic, forgettable products.

The `/creative-director` skill runs a structured interview — brand, experience, emotion,
motion, typography — and produces:
- **Creative Brief** — the "what it should feel like" document
- **Engineering Brief** — the technical requirements that support the creative intent

**Gate — output required before Phase 3:**
> Approved Creative Brief + Engineering Brief. The author explicitly signs off.
> Save as `.creative-brief.md` in the project root so future sessions find it.

If the feature has no UI (pure backend, infra, data pipeline), skip to Phase 3.

---

## Phase 3 — Spec

**Invoke: `/spec-authoring`**

Turn the creative brief and the author's intent into a structured feature spec. The spec
is what the implementer builds to — not the brief, not a Slack message, not memory.

The spec covers:
- Why this exists and what's explicitly out of scope
- EARS requirements (testable, one per line)
- LOCKED decisions (the implementer must follow exactly)
- OPEN decisions (the implementer may propose)
- Verbatim SQL/DDL/config where exactness matters
- Named tests mapped to each requirement
- Migration/rollback plan for schema changes

**Gate — output required before Phase 4:**
> `{SLUG}_SPEC.md` with status `READY FOR IMPL` (no open Sec11 blockers).
> If placeholders remain, the spec stays `DRAFT` and Phase 4 cannot start.

---

## Phase 4 — Stress Test

**Invoke: `/grill-me`**

Before breaking work into tickets, stress-test the spec. The grilling surfaces:
- Assumptions that sound obvious but aren't
- Missing edge cases
- Scope that will silently expand
- Decisions that look OPEN but will actually fail if the implementer chooses wrong

The author answers every challenge. Unresolved challenges go back into the spec as
LOCKED decisions or Sec11 blockers before Phase 5 begins.

**Gate — output required before Phase 5:**
> Revised spec that has survived the stress test. Author confirms: "This is ready."

---

## Phase 5 — Issues

**Invoke: `/to-issues`**

Break the approved spec into independently-grabbable issues on the project tracker.
Use tracer-bullet vertical slices — each issue delivers working, tested, reviewable
functionality on its own. Not "backend for X" + "frontend for X" as separate issues
unless the team works that way intentionally.

Each issue must include:
- Which requirement(s) it satisfies (R-numbers from the spec)
- Acceptance criteria (copy from the spec's EARS requirements)
- Which LOCKED decisions apply
- A link to the spec

**Gate — output required before Phase 6:**
> Issues created, numbered, and confirmed by the author. Assignees set.

---

## Phase 6 — Implementation (per issue)

Work each issue through the right sub-skills. Every issue follows this mini-pipeline:

### If backend work
1. **`/nest-endpoint-scaffold`** (or equivalent) — scaffold the endpoint
2. **`/tdd`** — write failing tests first, then implementation
3. **`/nest-integration-test`** — integration test covering happy path, auth, validation,
   cross-tenant isolation

### If UI work
1. **`/creative-director`** brief is already approved — reference it throughout
2. **`/build-ui-figma`** or **`/build-ui-stitch`** or **`/build-ui-from-design`** — the
   Creative Brief gate in these skills enforces the brief is present before building
3. Verify: active bug-hunt against design source AND against the Creative Brief

### For any work
- No implementation starts without the spec open
- LOCKED decisions are non-negotiable — flag any pressure to deviate
- The implementer ticks the spec's Sec9 self-check before raising a PR

**Gate — output required before Phase 7:**
> PR raised with Sec9 self-check in the description. All named tests from Sec8 exist
> and pass. No TypeScript / lint errors. Build is green.

---

## Phase 7 — Review & Deploy

### Code review
**Invoke: `/code-review`**

Walk the spec methodically against the PR (per spec-authoring Sec9 review checklist):
- Every LOCKED decision verifiable in the diff
- Every R-requirement has a matching named test
- Verbatim SQL/DDL matches Sec4c exactly
- Migration runs clean both ways

Do not approve on vibe. Every L, every R, every test must map.

### Deploy
**Invoke: `/railway-deploy`** (or the project's deploy skill)

Deploy only after the review is approved and all checks are green.

---

## The rules that enforce this workflow

These are standing rules in `AGENTS.md` — they apply in every session without invoking
this skill:

1. **No UI build without a Creative Brief.** The build skills will block and invoke
   `/creative-director` automatically.
2. **No implementation without a spec.** If asked to "just build it", ask for the spec.
3. **Phases are sequential.** A missing gate output is a blocker, not a suggestion.

---

## Quick reference — phase gates

| Phase | Skill | Gate output |
|---|---|---|
| 1 — Foundation | (manual) | `architecture-brief.md` + `CLAUDE.md` |
| 2 — Creative Direction | `/creative-director` | `.creative-brief.md` (author approved) |
| 3 — Spec | `/spec-authoring` | `{SLUG}_SPEC.md` at `READY FOR IMPL` |
| 4 — Stress Test | `/grill-me` | Revised spec, author confirms ready |
| 5 — Issues | `/to-issues` | Issues on tracker, assignees set |
| 6 — Implement | `/nest-endpoint-scaffold`, `/build-ui-*`, `/tdd` | PR with Sec9 self-check, green CI |
| 7 — Review + Deploy | `/code-review`, `/railway-deploy` | Approved PR, live deploy |
