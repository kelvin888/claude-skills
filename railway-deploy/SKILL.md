---
name: railway-deploy
description: Deploy a service to Railway and debug a failing deploy. Covers service setup, Dockerfile vs Nixpacks, environment variables, PORT binding, Postgres provisioning, migration-in-start, and monorepo root directories. Battle-tested on real NestJS + Prisma deployments.
---

# Deploy to Railway

## Step 1 — Identify the service shape
- Language/runtime, build tool, and start command.
- **Monorepo?** Set the service **Root Directory** to the subpackage (e.g. `stiz-backend/`),
  or builds will run from the repo root and miss the lockfile/package.
- Decide build method: Railway **Nixpacks** (auto) vs a committed **Dockerfile**.
  For anything with Prisma, native addons, or OpenSSL deps → **write a Dockerfile**.
  Nixpacks can guess wrong on Alpine builds and produces hard-to-debug errors.

## Step 2 — Dockerfile (preferred for NestJS + Prisma)

Multi-stage Alpine build that works on Railway:

```dockerfile
FROM node:20-alpine AS builder
RUN apk add --no-cache openssl          # Prisma requires OpenSSL — must be in BOTH stages
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine AS runner
RUN apk add --no-cache openssl          # required in runner too — Prisma query engine links it
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY prisma ./prisma
EXPOSE 3001
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
```

Key points:
- `openssl` in **both** stages — the query engine is a native binary that links against it at runtime.
- Copy `.prisma` and `@prisma` from builder to runner — these contain the generated client and the query engine binary.
- Copy `prisma/` folder (schema + migrations) to runner — `migrate deploy` needs the migration files at runtime.
- `migrate deploy` runs inside `CMD` so it executes on every container start, including crash-restarts. This is intentional — it's idempotent and ensures the DB is always in sync.

## Step 3 — Provision Postgres on Railway

1. In the Railway project, click **+ New** → **Database** → **PostgreSQL**.
2. In your backend service's **Variables** tab, add:
   ```
   DATABASE_URL=${{Postgres.DATABASE_PUBLIC_URL}}
   ```
   The `${{Postgres.DATABASE_PUBLIC_URL}}` syntax is a Railway reference variable — it picks up the current Postgres service's public proxy URL automatically. **Do not hardcode the connection string** — if you delete and recreate the Postgres service, the host/port changes and the hardcoded URL will point to a dead address.

3. Wait for Postgres to finish provisioning (green status) before triggering your first backend deploy.

## Step 4 — Environment variables

Set these on the **backend service** (not the Postgres service):

| Variable | Notes |
|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_PUBLIC_URL}}` — reference variable, not a hardcoded string |
| `JWT_SECRET` | Generate with `openssl rand -hex 32` |
| `ENCRYPTION_KEY` | 32-byte hex — generate with `openssl rand -hex 32` |
| `PAYSTACK_SECRET_KEY` | From Paystack dashboard |
| `GOOGLE_CLIENT_ID` | Use `placeholder` until real OAuth creds are ready — prevents startup crash (passport-google-oauth20 validates clientID at module init) |
| `GOOGLE_CLIENT_SECRET` | Use `placeholder` until real OAuth creds are ready |
| Any other required vars | Check startup logs — NestJS/ConfigService will throw the missing var name |

**Critical:** Variables must be set on the correct service. If you delete and recreate the Postgres service (e.g. to fix a crash loop), the variables on the backend service remain — but `DATABASE_URL` must be re-pointed to the new Postgres reference variable.

## Step 5 — Deploy and read logs

- Push to the connected branch or run `railway up` from the service root.
- Watch **Build logs** and **Deploy logs** separately.
- A successful build with a crashing start is a runtime/env problem, not a build one.
- Railway's free-tier Postgres can crash if the app hits it with too many failed connections in a loop — if the DB goes red, delete and recreate it.

## Battle-tested errors (NestJS + Prisma + Alpine)

### 1. Prisma / OpenSSL missing on Alpine
**Symptom:** `migrate deploy` or the app crashes with "Could not parse schema engine response" or a binary execution error. Build succeeds, deploy fails immediately.
**Cause:** Alpine doesn't ship OpenSSL. The Prisma query engine binary is dynamically linked against it.
**Fix:** Add `RUN apk add --no-cache openssl` to **both** the builder and runner stages in the Dockerfile. One stage missing it is enough to cause the crash.

### 2. DATABASE_URL pointing to a deleted Postgres
**Symptom:** Deploy fails with `P1001: Can't reach database server at <old-host>:<old-port>`. The host is an old proxy address that no longer exists.
**Cause:** The Postgres service was deleted and recreated. The `DATABASE_URL` variable was set as a hardcoded string (e.g. `postgresql://...@acela.proxy.rlwy.net:25054/railway`) that referenced the old service.
**Fix:** Delete the hardcoded `DATABASE_URL` and replace it with the Railway reference variable `${{Postgres.DATABASE_PUBLIC_URL}}`. This always resolves to the current Postgres service's proxy address.

### 3. Variables set on the wrong service
**Symptom:** `JWT_SECRET`, `ENCRYPTION_KEY`, or other vars are set but the app still crashes saying they're missing.
**Cause:** The variables were set while the Postgres service was selected in the Railway UI, not the backend API service.
**Fix:** Click on the **backend service** in the Railway project, go to **Variables**, and set the vars there.

### 4. Google OAuth strategy crashes on missing credentials
**Symptom:** App crashes at startup with `OAuth2Strategy requires a clientID option`.
**Cause:** `passport-google-oauth20` validates that `clientID` is present at module init time, even if Google login isn't used yet.
**Fix:** Set `GOOGLE_CLIENT_ID=placeholder` and `GOOGLE_CLIENT_SECRET=placeholder` until real Google OAuth credentials are ready. The strategy registers without crashing; actual Google login will fail gracefully until real creds are set.

### 5. Free-tier Postgres crash loop
**Symptom:** The Railway Postgres service goes red. Deploy logs show repeated `P1001` connection errors. The backend keeps restarting and hammering the DB with failed connections.
**Cause:** Railway free-tier Postgres has memory limits. A crash-looping app hammering it with connection attempts can push it over.
**Fix:** Delete the Postgres service and create a new one. Update `DATABASE_URL` to reference the new service (if using the reference variable `${{Postgres.DATABASE_PUBLIC_URL}}`, this is automatic).

### 6. PORT binding
NestJS `main.ts` must listen on `process.env.PORT` and bind to `0.0.0.0`:
```typescript
await app.listen(process.env.PORT ?? 3001, '0.0.0.0');
```
Railway injects `PORT` at runtime. The app must accept it — hardcoding `3001` means the app listens on the wrong port and Railway's health check never passes.

## Common gotchas (general Railway knowledge)
- App not binding `0.0.0.0:$PORT` → reachable locally, unreachable on Railway.
- Wrong root directory in a monorepo → "no package.json / lockfile" build failures.
- Migrations not run → app boots then crashes on first DB query.
- Missing runtime env var → crash loop; check Deploy logs for the thrown variable name.
- Build cache serving stale artifacts → trigger a clean build (Railway UI: redeploy without cache).
- Deleting a managed DB service invalidates any hardcoded connection strings — always use Railway reference variables.
