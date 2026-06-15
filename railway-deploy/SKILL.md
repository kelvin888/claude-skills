---
name: railway-deploy
description: Deploy a service to Railway and debug a failing deploy. Covers service setup, build vs start config, environment variables, PORT binding, health checks, and monorepo root directories. Use when the user wants to deploy to Railway, fix a Railway build/start failure, or set up a Railway service. NOTE — contains TODO placeholders for project-specific issues that must be filled in from real deploys.
---

# Deploy to Railway

> **STATUS: SKELETON.** The general flow and common gotchas below are reliable, but the
> sections marked `TODO (from our deploys)` need the specific errors and fixes we actually
> hit on Railway filled in. Until then, treat those as prompts to recall, not as fact.

---

## Step 1 — Identify the service shape
- Language/runtime, build tool, and start command.
- **Monorepo?** Set the service **Root Directory** to the subpackage (e.g. `backend/`),
  or builds will run from the repo root and miss the lockfile/package.
- Decide build method: Railway **Nixpacks** (auto) vs a committed **Dockerfile**. A
  Dockerfile is more predictable when Nixpacks guesses wrong.

## Step 2 — Build & start configuration
- **Build command** and **Start command** set explicitly (don't rely on inference for
  anything non-trivial).
- The app MUST bind to `0.0.0.0` and the port from **`process.env.PORT`** (Railway injects
  it). Hardcoding a port is the most common "deploy succeeds, app unreachable" cause.
- Health check path configured if the service should gate traffic on readiness.

## Step 3 — Environment variables
- Set all required env vars in the Railway service (not just `.env`, which isn't deployed).
- Reference other services (e.g. a managed Postgres) via Railway's provided variables
  (`DATABASE_URL`, etc.) rather than hardcoding connection strings.
- Distinguish **build-time** vs **run-time** vars — some frameworks need vars present at
  build.

## Step 4 — Deploy and read logs
- Trigger deploy (push to the connected branch, or `railway up` via CLI).
- Watch **Build logs** and **Deploy logs** separately — a green build with a crashing
  start is a runtime/config problem, not a build one.

## Common gotchas (general Railway knowledge)
- App not binding `0.0.0.0:$PORT` → reachable locally, dead on Railway.
- Wrong root directory in a monorepo → "no package.json / lockfile" build failures.
- Migrations not run → app boots then crashes on first DB query; run migrations in a
  release/start step.
- Missing run-time env var → crash loop; check Deploy logs for the thrown variable name.
- Build cache serving stale artifacts → trigger a clean build when behavior doesn't match
  the committed code.

## TODO (from our deploys) — fill these in
- [ ] The specific error(s) we hit and what each turned out to be
- [ ] The exact build/start commands that ended up working
- [ ] Any Nixpacks-vs-Dockerfile decision and why
- [ ] Root directory / monorepo settings used
- [ ] Migration / release-phase setup
- [ ] Env vars that tripped us up (names only — never commit secret values)
