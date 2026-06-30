<!--
  INTERSWITCH FEATURE SPEC — author guide (delete this comment block before handing off)

  Audience: a junior or mid engineer + Claude Code who will implement this with little
  back-and-forth. Write for someone who does NOT have your domain context.

  Three rules that make this spec work:
    1. LOCKED vs OPEN — be explicit about what must be built exactly as written vs where
       the implementer may propose. Juniors can't tell which decisions are load-bearing.
    2. VERBATIM the silent-failure bits — any SQL/JPQL/DDL/config where a plausible wrong
       answer still compiles goes in word-for-word, never described.
    3. SELF-CHECK criteria — the implementer verifies their own work against §9 before PR,
       so review isn't endless.

  Keep standing rules OUT of here — they live in agents.md. Keep reusable patterns OUT of
  here — reference the relevant Skill instead. This file is ONLY what's specific to THIS feature.

  Size rule: small feature → keep as one file. Large feature → split §3/§4-5/§7 into
  requirements.md / design.md / tasks.md, but keep this same section order.
-->

# Feature Spec: <FEATURE NAME>

| Field | Value |
|---|---|
| Spec ID | `<TEAM>-<SHORT-SLUG>` |
| Version | `0.1` (bump on every material change) |
| Author (senior/owner) | `<name>` |
| Implementer | `<junior/assignee or "TBD">` |
| Status | `DRAFT` → `READY FOR IMPL` → `IN PROGRESS` → `DONE` |
| Target repo / service | `<repo>` |
| Skills to load | `<e.g. idempotency, stored-proc-dao, code-review>` |
| Standing rules | This service's `agents.md` is authoritative. This spec never overrides it; if it must, say so explicitly in §4a. |

## 0. TL;DR
<!-- 3 sentences max. What changes, for whom, and the single most important constraint. -->
`<...>`

## 1. Context & why now
<!-- The problem in business terms. Why this matters and why now. The "why behind the feature" so
     the implementer doesn't optimise for the wrong thing. Link the ticket/RFC. -->
`<...>`

## 2. Scope
**In scope**
- `<...>`

**Explicitly out of scope** <!-- This section prevents the agent from wandering. Be ruthless. -->
- `<...>`

## 3. Requirements — acceptance criteria (EARS)
<!-- Use EARS sentence patterns. Each line is independently testable. This is what §8 tests and §9
     verifies against. Patterns:
       Ubiquitous:      The <system> SHALL <response>.
       Event-driven:    WHEN <trigger>, the <system> SHALL <response>.
       State-driven:    WHILE <state>, the <system> SHALL <response>.
       Unwanted:        IF <condition>, THEN the <system> SHALL <response>.
       Optional:        WHERE <feature included>, the <system> SHALL <response>. -->
- R1. `WHEN <trigger>, the system SHALL <response>.`
- R2. `IF <error condition>, THEN the system SHALL <response>.`
- R3. `<...>`

## 4. Design — how to build it

### 4a. LOCKED decisions — implement exactly, do NOT deviate
<!-- The load-bearing choices. If the implementer thinks one is wrong, they STOP and ask you —
     they do not silently change it. This is the "implement directly" half of the handoff. -->
- L1. `<e.g. payment_events is append-only — no UPDATE/DELETE ever>`
- L2. `<...>`

### 4b. OPEN decisions — implementer/Claude MAY propose
<!-- Where you deliberately leave room. The "augment and implement" half. For each, say what
     "good" looks like so proposals come back in-bounds. -->
- O1. `<decision>` — propose 2–3 options with trade-offs, recommend one, proceed after `<approval / or proceed if low-risk>`.
- O2. `<...>`

### 4c. VERBATIM artifacts — copy exactly, do not paraphrase
<!-- DDL, JPQL, native SQL, stored-proc signatures, config keys, regexes — anything that fails
     silently if reworded. Per agents.md: simple find/save = JPA; complex/reporting = stored proc;
     application.properties only; PostgreSQL only. -->
```sql
-- <DDL / stored proc / native query goes here, exactly>
```

## 5. Data model & schema changes
<!-- Tables, columns, types, constraints, indexes, FKs. Money = NUMERIC/BigDecimal, never float.
     Currency = ISO 4217. Include the Flyway migration filename(s) under src/main/resources/db/migration/. -->
`<...>`

## 6. Package & file map
<!-- Where each new/changed file goes. Layer-based per agents.md: api / service / dao / model / utils
     under com.interswitch.<project>.<project>service. Name the files so the implementer doesn't guess. -->
```
com.interswitch.<project>.<project>service/
├── api/        <...>
├── service/    <...>
├── dao/        <...>
└── model/      <...>
```

## 7. Tasks — ordered execution plan
<!-- Atomic, ordered steps. Claude Code follows this order. Each step should be independently
     verifiable. Front-load schema/migration, then DAO, then service, then API, then tests. -->
1. `<...>`
2. `<...>`

## 8. Test plan — named tests
<!-- Name each test and what it verifies, mapped back to R1/R2... Naming them stops the agent from
     writing happy-path-only tests. Call out the edge cases that matter. -->
- `should<...>` → verifies R`<n>`
- `should<...>` → verifies R`<n>`

## 9. Verification checklist — implementer self-checks before raising PR
<!-- The implementer ticks every box themselves. Keep to things NOT auto-enforced by linter/CI
     (those belong in the toolchain, not here). -->
- [ ] All §3 acceptance criteria have a passing named test from §8
- [ ] Every §4a LOCKED decision implemented as written (no silent deviation)
- [ ] Every §4c VERBATIM artifact copied exactly
- [ ] Money handled as `BigDecimal`/`NUMERIC`; currency explicit
- [ ] Migration runs clean forward; rollback path in §10 verified
- [ ] No new SQL Server / yml / multi-module drift (agents.md compliance)
- [ ] `<feature-specific check>`

## 10. Migration, rollout & rollback
<!-- For schema/data changes especially. Dual-write? Backfill? Cutover? How to roll back if it
     goes wrong mid-deploy. Zero-downtime considerations. -->
`<...>`

## 11. Open questions for the author
<!-- Park unknowns here instead of guessing. The implementer adds to this list rather than
     inventing answers; you resolve them and bump the version. -->
- Q1. `<...>`
