# EARS acceptance criteria & the LOCKED/OPEN discipline

Read this when writing Sec3 (requirements) and Sec4 (design) of a feature spec.

## EARS — five sentence patterns for testable requirements

EARS (Easy Approach to Requirements Syntax) turns fuzzy requirements into unambiguous,
testable statements. Every criterion in Sec3 should fit one of these five shapes. The value:
each one maps 1:1 to a named test in Sec8, so "done" is objective.

| Pattern | Shape | Use for |
|---|---|---|
| Ubiquitous | `The <system> SHALL <response>.` | Always-true invariants |
| Event-driven | `WHEN <trigger>, the <system> SHALL <response>.` | Responses to an input/event |
| State-driven | `WHILE <state>, the <system> SHALL <response>.` | Behaviour during a condition |
| Unwanted | `IF <condition>, THEN the <system> SHALL <response>.` | Error/abuse handling |
| Optional | `WHERE <feature included>, the <system> SHALL <response>.` | Behaviour behind a flag |

**Good:** `IF a request reuses an idempotency key with a different body, THEN the system SHALL return 409.`
**Bad:** `Handle duplicate requests gracefully.` (untestable — the agent will guess what "gracefully" means)

One requirement per line. No "and also". If you need "and", it's two requirements.

## LOCKED vs OPEN — the senior→junior contract

This is what separates a spec a junior can implement *directly* from one they must *augment*.
A junior cannot tell which of your decisions are load-bearing. Tell them.

**LOCKED (Sec4a)** — implement exactly. If the implementer believes a LOCKED decision is wrong,
they STOP and ask; they do not silently change it. Lock a decision when getting it wrong fails
silently, breaks a contract, or violates compliance. In payments that's: money types, idempotency
semantics, append-only/audit guarantees, transaction boundaries, concurrency control.

**OPEN (§4b)** — the implementer (or Claude in plan mode) may propose. Use this where you
genuinely don't mind the approach, or want a junior to exercise judgement and grow. For each OPEN
item, state what "good" looks like and the approval bar, so proposals come back in-bounds:
> O1. Event-application path (JPA vs stored proc). Propose 2–3 options with trade-offs, recommend one,
> proceed after my approval.

Rule of thumb: if a wrong choice is *expensive or invisible*, LOCK it. If it's *cheap and visible
in review*, leave it OPEN and let the implementer learn.

## VERBATIM — what to paste word-for-word (§4c)

Anything where a plausible-looking wrong answer still compiles and passes a shallow test:
DDL, JPQL with non-trivial `ORDER BY`, native SQL, stored-proc signatures, config keys, regexes,
SHA/hash canonicalisation rules. Paste it; don't describe it. Describing `ORDER BY` logic is how
merchant-override bugs ship silently.

## What does NOT belong in a feature spec

- **Standing rules** (Java version, properties-not-yml, PostgreSQL-only, package layout) → `agents.md`.
- **Reusable patterns** (how to implement idempotency in general, the stored-proc DAO pattern) → a **Skill**.
- **Anything a linter/formatter/CI already enforces** → leave it to the tool; restating it just
  bloats the spec and (per 2026 research) measurably lowers agent success.

The spec contains only what is specific to *this* feature.
