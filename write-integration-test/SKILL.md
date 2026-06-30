---
name: write-integration-test
description: Write a NestJS integration test that exercises a controller end-to-end with the full pipeline — guards, pipes, filters, interceptors. Use when adding a `.integration.spec.ts` file, when the user says "integration test", "write test", "test the endpoint", or when scaffolding tests for a new controller. Stack-agnostic — reads CLAUDE.md first, asks about DB/auth strategy if not found. Covers harness setup, seed handling, auth helpers, and common gotchas.
---

# Nest Integration Test

Builds a single `*.integration.spec.ts` file that exercises a controller end-to-end
against a real database with the full NestJS pipeline. No mocks of internal collaborators.

## Step 0 — Detect the test strategy before writing anything

Read `CLAUDE.md` / `agents.md` and the existing test files to derive:

| Question | Where to look | If not found |
|---|---|---|
| Test DB approach | Existing `*.integration.spec.ts`, `package.json` devDeps | Ask: "mongodb-memory-server, pg test container, SQLite in-memory, or test DB URL?" |
| Auth strategy | Existing guards, test auth helpers | Ask: "How do tests authenticate — signup flow, seeded token, mock JWT, API key?" |
| Seed approach | Existing `beforeAll` in spec files, seed services | Ask: "Does the app auto-seed on module init, or do tests seed manually?" |
| Global prefix | `main.ts` | Read it — prefix must match what tests send |
| Global pipes/filters/interceptors | `main.ts` | Mirror them in the harness exactly |

Check `package.json` for which testing library the project uses (Jest vs Vitest). The
skeleton below uses Jest — adapt `describe/it/beforeAll/afterAll` to Vitest if needed.

---

## Philosophy

These are **behavioural tests**. They send HTTP, assert HTTP. They don't poke at
services or repositories directly. If you're injecting a service to call its methods,
that's a unit test — keep it separate and small.

Integration tests survive refactors because they only know the public surface.

---

## File location

```
src/modules/{module}/{feature}/{feature}.integration.spec.ts
```

Co-located with the controller it tests.

---

## The harness skeleton

```typescript
// Disable the lint rule that fires on supertest's loose `any` types
/* eslint-disable @typescript-eslint/no-unsafe-argument */

import { INestApplication, ValidationPipe } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import request from 'supertest'
import { AppModule } from '@/app.module'

// ── DB teardown helpers (pick the one that matches your stack) ──────────────
// MongoDB:   import { MongoMemoryServer } from 'mongodb-memory-server'
//            import mongoose from 'mongoose'
// PostgreSQL test container / SQLite: add your teardown client here

describe('{Feature}Controller (integration)', () => {
  let app: INestApplication
  // let mongo: MongoMemoryServer  // MongoDB only

  beforeAll(async () => {
    // ── 1. Start test database ────────────────────────────────────────────
    // MongoDB:
    //   mongo = await MongoMemoryServer.create()
    //   process.env.MONGODB_URI = mongo.getUri()
    //
    // PostgreSQL in-memory / SQLite:
    //   set process.env.DATABASE_URL to your test DB before module init

    // ── 2. Set required env vars BEFORE createTestingModule ──────────────
    // The module reads env at init time — set everything first.
    // process.env.JWT_SECRET = 'test-secret-at-least-32-chars-long'
    // Add any other secrets your app reads at startup

    // ── 3. Boot the app ──────────────────────────────────────────────────
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile()

    app = moduleRef.createNestApplication()

    // Mirror main.ts exactly — missing any of these causes hard-to-debug failures:
    // app.setGlobalPrefix('v1')            // if main.ts sets a prefix
    // app.use(cookieParser())              // if main.ts uses cookie-parser
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        // Use the same errorHttpStatusCode as main.ts — often 422, not the 400 default
      }),
    )
    // app.useGlobalFilters(new YourExceptionFilter())
    // app.useGlobalInterceptors(new YourResponseInterceptor())

    await app.init()

    // ── 4. Seed if the app does NOT auto-seed on module init ─────────────
    // If the app seeds via onModuleInit, do NOT call seed() again here —
    // calling it twice causes duplicate-key errors.
    // If tests need explicit seeding:
    //   const seeder = app.get(YourSeederService)
    //   await seeder.seed()
  })

  afterAll(async () => {
    await app.close()
    // MongoDB:   await mongoose.disconnect(); await mongo.stop()
    // Prisma:    prisma.$disconnect() if you injected it
    // TypeORM:   dataSource.destroy()
  })

  // ── Tests go here ─────────────────────────────────────────────────────────
})
```

---

## Auth helper

Adapt this to the project's actual auth endpoints and request shape:

```typescript
async function authenticate(
  email = 'test@example.com',
  // Add any other fields your signup/login endpoint requires
): Promise<{ token: string; userId: string }> {
  // Option A — signup + login flow (most common)
  const res = await request(app.getHttpServer())
    .post('/v1/auth/signup')          // change to your auth path
    .send({ email, password: 'Test@1234', /* other required fields */ })
    .expect(201)

  return {
    token: res.body.data?.accessToken ?? res.body.accessToken,
    userId: res.body.data?.user?.id   ?? res.body.id,
  }

  // Option B — if tests use a pre-seeded user and a login endpoint instead
  // const res = await request(app.getHttpServer())
  //   .post('/v1/auth/login')
  //   .send({ email, password: 'seeded-password' })
  //   .expect(200)
  // return { token: res.body.data.accessToken, userId: res.body.data.user.id }
}
```

---

## Test shape — minimum coverage per endpoint

```typescript
it('returns 201 and the created resource on valid input', async () => {
  const { token } = await authenticate()

  const res = await request(app.getHttpServer())
    .post('/v1/{resource}')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'Test item' })
    .expect(201)

  expect(res.body.data).toMatchObject({ name: 'Test item' })
  expect(res.body.data.id).toBeDefined()
})

it('returns 401 when no token is provided', async () => {
  await request(app.getHttpServer())
    .post('/v1/{resource}')
    .send({ name: 'Test item' })
    .expect(401)
})

it('returns 403 when the caller lacks the required permission', async () => {
  const { token } = await authenticate('low-perm@example.com')
  await request(app.getHttpServer())
    .post('/v1/{resource}')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'Test item' })
    .expect(403)
})

it('returns a validation error on bad input', async () => {
  const { token } = await authenticate()
  await request(app.getHttpServer())
    .post('/v1/{resource}')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: '' })         // violates @Length(2, 80)
    .expect(422)                // or 400 — match your ValidationPipe config
})

it('returns 404 when the resource belongs to another tenant', async () => {
  const { token } = await authenticate('other@example.com')
  await request(app.getHttpServer())
    .get('/v1/{resource}/someone-elses-id')
    .set('Authorization', `Bearer ${token}`)
    .expect(404)   // 404, not 403 — don't leak existence across tenants
})
```

Write one test per behaviour. For conflict (duplicate / wrong state) add a 409 test.

---

## Status codes cheat sheet

| Situation | Expected |
|---|---|
| Successful create | 201 |
| Successful read / update | 200 |
| Successful delete (no body) | 204 |
| Missing / invalid token | 401 |
| Valid token, permission missing | 403 |
| Resource not found or not in caller's scope | 404 |
| Conflict (duplicate, wrong state, still referenced) | 409 |
| DTO validation failure | 422 (or 400 — match your project) |

---

## Gotchas (common failure patterns)

| Symptom | Cause | Fix |
|---|---|---|
| `E11000 duplicate key` on seed data | Test called `seed()` AND `onModuleInit` auto-seeds | Remove the explicit `seed()` call. Let `onModuleInit` handle it. |
| Validation returns 400, test expects 422 | `errorHttpStatusCode` not set in `ValidationPipe` | Add `errorHttpStatusCode: 422` to match your `main.ts` config. |
| `AppError` subclass returns 500 | Exception filter not registered in harness | Add `app.useGlobalFilters(new YourExceptionFilter())` |
| `res.body.id` is undefined but data is present | Response interceptor wraps in `{ data: ... }` | Assert on `res.body.data.id`, not `res.body.id`. |
| Tests hang after completion | DB connection not closed in `afterAll` | Disconnect client + stop in-memory server in `afterAll`. |
| Secret-related 500s | Env vars not set before `createTestingModule` | Set all `process.env.*` before calling `Test.createTestingModule`. |
| Cookie-based auth fails | Cookie parser middleware missing | Add `app.use(cookieParser())` — mirror `main.ts`. |
| `request(server)` lint errors everywhere | `app.getHttpServer()` returns `any` | Add `/* eslint-disable @typescript-eslint/no-unsafe-argument */` at file top. |
| "Address already in use" in CI | Multiple spec files share one in-memory DB server | Each `*.integration.spec.ts` must create and stop its own DB server. |

---

## Verification

```bash
# Run just this test file
npx jest path/to/feature.integration.spec.ts --runInBand

# Full suite
npx jest
# or: pnpm test / yarn test — match the project's script
```

`--runInBand` runs tests serially in the same process — useful for integration tests that
share an in-memory DB to avoid port conflicts.
