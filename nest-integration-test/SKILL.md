---
name: nest-integration-test
description: Write a NestJS integration test using mongodb-memory-server + supertest, following the TradeAxis backend conventions. Use when adding a `.integration.spec.ts` file, when the user says "integration test", "write test", "test the endpoint", or when scaffolding tests for a new controller. Covers harness setup, seed handling, auth helpers, and the gotchas that bite (422 vs 400, duplicate-seed race, supertest typing).
---

# Nest Integration Test

Builds a single `*.integration.spec.ts` file that exercises a controller end-to-end
against a real MongoDB (in-memory) with the full NestJS pipeline — guards, pipes,
filters, interceptors. No mocks of internal collaborators.

## Philosophy

These are **behavioural tests**. They send HTTP, assert HTTP. They don't poke at
services or repositories directly. If you find yourself injecting `RolesService` to
call methods, stop — that's a unit test, write that separately and keep it small.

Integration tests survive refactors because they only know the public surface.

## File location

```
src/modules/{module}/{feature}/{feature}.integration.spec.ts
```

Co-located with the controller it tests. Jest finds it via the default `*.spec.ts`
glob.

## The harness skeleton (copy and adapt)

```typescript
/* eslint-disable @typescript-eslint/no-unsafe-argument */
// ^ supertest's request(server) types are loose; this disable goes at the file top.

import { INestApplication, ValidationPipe } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import cookieParser from 'cookie-parser'
import { MongoMemoryServer } from 'mongodb-memory-server'
import mongoose from 'mongoose'
import request from 'supertest'
import { AppModule } from '@/app.module'
import { GlobalExceptionFilter } from '@/shared/filters/http-exception.filter'
import { ResponseTransformInterceptor } from '@/shared/interceptors/response-transform.interceptor'

describe('RolesController (integration)', () => {
  let app: INestApplication
  let mongo: MongoMemoryServer

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create()
    process.env.MONGODB_URI = mongo.getUri()
    process.env.JWT_SECRET = 'test-secret-at-least-32-chars-long-xxxxxx'
    process.env.JWT_REFRESH_SECRET = 'test-refresh-at-least-32-chars-long-xxx'

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile()

    app = moduleRef.createNestApplication()
    app.setGlobalPrefix('v1')
    app.use(cookieParser())
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        errorHttpStatusCode: 422, // CRITICAL: default is 400; we want 422
      }),
    )
    app.useGlobalFilters(new GlobalExceptionFilter())
    app.useGlobalInterceptors(new ResponseTransformInterceptor())

    await app.init()
    // DO NOT call seed.seed() here — IdentitySeedService.onModuleInit awaits the seed
    // already. Calling it twice triggers E11000 duplicate key.
  })

  afterAll(async () => {
    await app.close()
    await mongoose.disconnect()
    await mongo.stop()
  })

  // tests go here
})
```

## Why each line matters (don't skip)

- **`process.env.MONGODB_URI = mongo.getUri()` BEFORE `Test.createTestingModule`** —
  `MongooseModule.forRoot` reads the env at module init. Set it first.
- **`process.env.JWT_SECRET`** — `JwtModule.register` reads it; tests fail with
  cryptic 500s if missing.
- **`app.setGlobalPrefix('v1')`** — production sets this in `main.ts`. Without it,
  tests would have to use `/auth/signup` instead of `/v1/auth/signup` and drift from
  production behaviour.
- **`cookieParser()`** — refresh tokens come back as httpOnly cookies; tests that
  exercise `/v1/auth/refresh` need this or the cookie is invisible.
- **`errorHttpStatusCode: 422`** — the project convention is 422 for validation
  errors, not the NestJS default 400. Forgetting this gives "expected 422, got 400"
  failures that look like a test bug but are actually a setup bug.
- **`useGlobalFilters` + `useGlobalInterceptors`** — `main.ts` registers these; tests
  must mirror it. Without the filter, `AppError` subclasses return 500. Without the
  interceptor, responses come back as raw objects (no `data` wrapper) and assertions
  fail.
- **`/* eslint-disable @typescript-eslint/no-unsafe-argument */`** — `app.getHttpServer()`
  returns `any`; supertest's `request(server)` then types as `any` too. The lint rule
  fires on every call. Disable at file top, not per-line.

## Test shape (one per behaviour)

```typescript
it('creates a custom role and returns 201 with the role summary', async () => {
  const { token } = await signupAndLogin('owner@acme.com', 'importer')

  const res = await request(app.getHttpServer())
    .post('/v1/organizations/me/roles')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Procurement Officer',
      permissions: ['procurement.rfq.create', 'procurement.rfq.view'],
    })
    .expect(201)

  expect(res.body.data).toMatchObject({
    name: 'Procurement Officer',
    permissions: expect.arrayContaining(['procurement.rfq.create']),
    isSystem: false,
  })
  expect(res.body.data.id).toBeDefined()
})

it('rejects a role with permissions outside the org group with 403', async () => {
  const { token } = await signupAndLogin('owner@acme.com', 'importer')

  await request(app.getHttpServer())
    .post('/v1/organizations/me/roles')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'Admin Smuggler', permissions: ['admin.platform.manage'] })
    .expect(403)
})
```

**Assert on `res.body.data`** — never `res.body` directly. The interceptor wraps it.
Errors come back as `res.body.error`.

## Auth helper (paste into the spec, or into a shared `test-helpers.ts`)

```typescript
async function signupAndLogin(
  email: string,
  group: 'importer' | 'supplier' | 'admin' = 'importer',
): Promise<{ token: string; userId: string; organizationId: string }> {
  const signup = await request(app.getHttpServer())
    .post('/v1/auth/signup')
    .send({
      email,
      password: 'P@ssw0rd-test-2026',
      name: 'Test User',
      organizationName: 'Test Org',
      group,
      country: 'NG',
    })
    .expect(201)

  return {
    token: signup.body.data.accessToken,
    userId: signup.body.data.user.id,
    organizationId: signup.body.data.user.organizationId,
  }
}
```

If your endpoint requires a specific permission the default role doesn't include
(e.g. testing as a non-owner), do a second signup + invite + accept flow rather than
manually mutating roles. Tests should use the same paths users do.

## Status-code assertions cheat sheet

| What you're testing | `.expect(...)` |
|---|---|
| Successful create | `.expect(201)` |
| Successful read/update | `.expect(200)` |
| Successful delete | `.expect(204)` |
| Missing/invalid JWT | `.expect(401)` |
| Permission missing | `.expect(403)` |
| Resource not found / not in caller's org | `.expect(404)` |
| Conflict (duplicate, still referenced) | `.expect(409)` |
| Bad input (DTO validation) | `.expect(422)` |

## Gotchas (the ones that have actually bitten this project)

| Symptom | Cause | Fix |
|---|---|---|
| `E11000 duplicate key` on permission/role | Test called `seed.seed()` AND `OnModuleInit` ran | Remove the explicit `seed.seed()` call. `onModuleInit` awaits internally. |
| Test expects 422, gets 400 | `errorHttpStatusCode: 422` missing from `ValidationPipe` | Add it. |
| `AppError` returns 500 | `GlobalExceptionFilter` not registered | `app.useGlobalFilters(new GlobalExceptionFilter())` |
| `res.body.id` undefined, but the data is there | `ResponseTransformInterceptor` missing | Add it. Then assert on `res.body.data.id`. |
| Test hangs in CI | `mongoose.disconnect()` missing in `afterAll` | Add it. Order: `app.close()` → `mongoose.disconnect()` → `mongo.stop()`. |
| `JWT_SECRET is required` 500 | Env not set before `createTestingModule` | Set `process.env.JWT_SECRET` in `beforeAll` before the `Test.createTestingModule` call. |
| Refresh-token tests fail to read cookie | `cookieParser` middleware not registered | `app.use(cookieParser())` |
| `request(server)` lint errors everywhere | `@typescript-eslint/no-unsafe-argument` on `any` | Disable at file top: `/* eslint-disable @typescript-eslint/no-unsafe-argument */` |
| Test passes locally, fails in CI with "address already in use" | Multiple test files share a `MongoMemoryServer` port | Each `*.integration.spec.ts` creates its OWN `MongoMemoryServer`. Don't share. |

## Coverage targets per endpoint

For each endpoint, write at minimum:

1. **Happy path** — valid input, expected response shape
2. **Auth** — no token returns 401; wrong-permission user returns 403
3. **Validation** — at least one DTO failure mode returns 422
4. **Cross-tenant isolation** — a user from another org returns 404 (not 403; we don't
   leak existence)
5. **Conflict path** (if applicable) — duplicate / wrong-state returns 409

These five together hit the surface area that matters. Don't over-test the schema
itself — Mongoose validators are not your job.

## Verification

```bash
pnpm test path/to/feature.integration.spec.ts
# or full suite:
pnpm test
```

If you see `MongoServerError: E11000 duplicate key error` on a fresh test run, jump
straight to the seed gotcha row above — that's almost always it.
