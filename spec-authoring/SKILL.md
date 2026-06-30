---
name: spec-authoring
description: Use this skill whenever a senior or domain expert needs to write a feature specification to hand off to another engineer (often a junior) to implement, or when anyone says "write a spec", "spec this out", "create a feature spec", "hand-off doc", "implementation spec", or is about to delegate a coding task. Also trigger when someone describes a feature or schema change they want built by someone else, even if they don't use the word "spec". Produces a structured, locked/open, EARS-based spec from the FEATURE_SPEC_TEMPLATE that a junior + Claude Code can implement with minimal back-and-forth. Stack-agnostic — detects the project's stack from CLAUDE.md/agents.md or asks the author.
---

# Spec Authoring

Turn a senior engineer's intent into a feature spec a junior can implement directly — or augment
and implement — with minimal back-and-forth. The output is a filled-in copy of
`assets/FEATURE_SPEC_TEMPLATE.md`.

## The layered model (know where things go)

A spec is one of three layers. Keep them separate or specs rot:
1. **`agents.md`** — standing, durable rules for the whole repo. Never restate these in a spec.
2. **Skills** — reusable procedures (idempotency, stored-proc DAO, code review). Reference, don't inline.
3. **This feature spec** — only what's specific to THIS task. That's what we author here.

If something you're about to write is true for *every* feature, it belongs in `agents.md`, not here.
If it's a pattern reused *across* features, it belongs in a Skill. The spec is the remainder.

## Workflow

### 1. Read the template and the reference
Before writing anything, read `assets/FEATURE_SPEC_TEMPLATE.md` (the structure) and
`references/ears-and-locked-open.md` (how to write Sec3 and Sec4 well). For a payments/schema example
of a completed spec, read `references/payments-table-split-example.md`.

### 2. Establish and bound scope before exploring
Do NOT crawl the whole repo. In a large project that wastes time and context and buries the signal,
and the author usually already knows the target area. Before any exploration, pin the scope down:
- Confirm in one line which module/domain and which **entry points** matter — e.g. "payments and
  every entry point into transaction processing" means the payment controllers, message
  listeners/consumers, scheduled jobs, and any API that initiates or advances a transaction.
- Treat that as a hard boundary. Bound ALL subsequent reading — stack detection (step 5), file
  discovery, dependency lookups — to it. Read the nearest `agents.md`/`CLAUDE.md` and the build
  manifest of the **relevant module** (in a monorepo the nearest file wins, not the root), plus the
  named entry points and what they directly call — not the whole tree.
- Only widen beyond scope when something in-scope references a contract you must pin down, and then
  read just that, not its neighbourhood.

If the author hasn't given scope, ask for it before exploring — "which area and which entry points?"
up front beats a full-repo scan every time. The scope you establish here also feeds Sec2 (in/out of
scope) of the spec.

### 3. Interview the author for the non-inferable bits
Don't generate a spec from thin air — that produces confident-but-wrong placeholders. Ask the
author (briefly, batched) for what only they know:
- The **why now** and the business pain (Sec1).
- What's **explicitly out of scope** (Sec2) — this prevents the implementer wandering.
- The **load-bearing decisions** that must be LOCKED (Sec4a) vs where the implementer may propose (Sec4b).
- Any **verbatim artifacts** — exact DDL, JPQL, SQL, config — they already have in mind (Sec4c).
- **Acceptance criteria** in plain language; you convert these to EARS (Sec3).
- Migration/rollback constraints for schema or data changes (Sec10).

Where the author doesn't know yet, write a clear **placeholder** in `<angle brackets>` and add the
question to Sec11 — never invent an answer that looks authoritative.

### 4. Fill the template in order
Produce a copy of the template with every section addressed. Discipline that matters most:
- **Sec3 in EARS.** One testable requirement per line. Convert vague asks ("handle errors") into
  `IF <condition>, THEN the system SHALL <response>.`
- **Sec4a LOCKED vs Sec4b OPEN.** Be explicit. This is the whole point — it's what tells a junior what
  they may touch. Lock anything where a wrong choice fails silently or breaks a contract/compliance.
- **Sec4c VERBATIM.** Paste exact SQL/JPQL/DDL/config. Never describe `ORDER BY` logic — paste it.
- **Sec8 named tests**, each mapped to a requirement, so the agent doesn't write happy-path-only tests.
- **Sec9 self-check** the implementer ticks before PR — only things NOT already enforced by linter/CI.

### 5. Detect the project's stack — do NOT assume it (within scope)
Never hardcode a stack. Read the target repo to learn what it actually uses, bounded to the scope set
in step 2 — the relevant module, not the whole tree. Check, in this order:
- **`agents.md` / `CLAUDE.md` at the repo root first** — the authoritative source of standing rules
  (language version, build tool, config format, database, persistence pattern, package layout). If it
  exists, follow it and do NOT restate its rules as requirements.
- **Build manifest** — `pom.xml` / `build.gradle` for Java version, framework version, and
  dependencies; `package.json` / `go.mod` / etc. for non-Java services.
- **Config + drivers** — `application.properties` vs `application.yml`; the DB driver dependency
  (PostgreSQL vs SQL Server vs other); Redis / Kafka presence and how they're configured.
- **Existing package structure** — layer-based vs feature-based, single- vs multi-module — match
  what's already there rather than imposing a layout.

Whatever the project already uses IS the default for this spec. Don't restate inferable stack facts
as requirements (that bloats the spec and measurably lowers agent success); assume them, and only
call a stack choice out in Sec4a if THIS feature must deviate from the repo norm — and say why.

**If the project is new / greenfield** (no code and no `agents.md`/`CLAUDE.md` to read): don't invent
silently. Propose a default stack, explain the reasoning, and ask the author to confirm before writing
the spec. Interswitch's common conventions are a reasonable starting suggestion to offer — Java 21 +
Spring Boot, `application.properties`, PostgreSQL, single-module, hybrid JPA/stored-proc, Redis
Sentinel, money as `BigDecimal`/`NUMERIC` — but present them as a recommendation to confirm, never as
a fact to assume. Once confirmed, recommend seeding an `agents.md` so the next spec can simply read it.

### 6. When you can't read a dependency — ask, don't fabricate
A spec often depends on contracts you cannot see: an internal/private library, a binary-only artifact,
an internal service API, or existing code in a repo you don't have access to. First make a genuine
attempt to find the ground truth — search the repo, check for vendored source, Javadoc, or an
interface definition. If it's genuinely unreachable (private Maven artifact, separate private repo,
compiled-only dependency), STOP and ask the author to paste the exact thing the spec needs — method
signatures, return types, thrown exceptions / error semantics, the DDL, the event contract — scoped
precisely to what's required. Never invent a plausible-looking API: an imagined internal signature
compiles fine in the spec and then breaks at implementation, which is exactly the silent failure the
spec exists to prevent.

Ask for the specific item, not the whole library — e.g. "paste the signature and thrown exceptions of
`IswSettlementClient.settle(...)`," not "share the settlement code." Once provided, drop the real
contract into Sec4c verbatim, and record anything still missing in Sec11 as a blocker that keeps the spec
in `DRAFT`.

### 7. Size decision — one file or three
- **Small feature** → keep the whole spec as one file.
- **Large feature** (schema splits, new subsystems) → split Sec3 / Sec4-5 / Sec7 into
  `requirements.md` / `design.md` / `tasks.md` with the same section content, so the author can hand
  the implementer one phase at a time and keep each context window clean. Keep Sec0-2 in a short
  parent `spec.md` that links the three.

### 8. Output
Write the finished spec to the repo next to the code it will produce (specs are versioned and owned
like code). Name it `<SLUG>_SPEC.md`. Tell the author which placeholders and Sec11 questions still
need their input before it moves from `DRAFT` to `READY FOR IMPL`.

### 9. Reviewing the PR — closing the loop (author's checklist)
After the implementer raises a PR, the author verifies it was built to spec. Do NOT review on vibe.
Walk the spec methodically:

1. **Require the Sec9 self-check in the PR description.** The implementer must paste the checklist from
   Sec9 with every box ticked. Unticked items must be explained as PR comments. This is a gate — no
   review starts until the self-check is acknowledged.

2. **Audit Sec4a (LOCKED) line by line.** Each L-item must be verifiable in the diff. If L1 says "no
   UPDATE on table X", grep the DAO for update methods on that table. If absent, annotate the PR
   line and cite the L-number.

3. **Diff Sec4c VERBATIM against the actual SQL.** Run `git diff` on migration files and compare
   column-by-column against the verbatim block in the spec. Column renames, type changes, missing
   constraints — each is a violation.

4. **Trace every R-requirement to a matching test.** Map R1 → `shouldXyz()` in Sec8 → actual test
   file in the PR. If an R has no matching test, it's not done.

5. **Check the migration runs clean both ways.** Forward migration (rollout) and the rollback
   path from Sec10 must be verified. If the spec says "truncate new tables to roll back", confirm
   no foreign key would block the truncate.

6. **Check edge cases from Sec8 are covered.** Don't let the implementer get away with happy-path-only
   tests. The named tests in Sec8 are your contract — if `shouldSweepAbandonedTransactions` isn't in
   the PR, the sweep logic is untested.

7. **Approve only when every L, every R, and every test name maps.** If something genuinely needs
   to change (not a deviation — a valid update), update the spec version first and note the change,
   then approve.

## Anti-patterns to avoid
- Crawling the whole repo when the author already knows the target area. Establish scope first
  (step 2) and bound all reading to it; a full-repo scan in a large project wastes context and buries
  the signal.
- Auto-generating a verbose spec full of inferable detail — 2026 research shows this lowers agent
  success and raises cost. Signal density beats completeness.
- Restating `agents.md` rules or linter-enforced style as requirements.
- Vague acceptance criteria with no test mapping.
- Leaving LOCKED vs OPEN implicit — the junior then either over-reaches or freezes.
- Inventing authoritative-looking values for things the author hasn't decided. Use placeholders + Sec11.
- Fabricating the contract of an internal library or service you can't read, instead of asking the
  author to paste the exact signature/DDL/contract. Guessing here defeats the whole point of the spec.

## Output template
ALWAYS base the output on `assets/FEATURE_SPEC_TEMPLATE.md`. Do not invent a different structure —
consistency across authors is the point, so every junior knows where to look.
