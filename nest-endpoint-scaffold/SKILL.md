---
name: nest-endpoint-scaffold
description: Scaffold a new REST endpoint in a NestJS modular monolith following the TradeAxis backend conventions. Use when adding routes to an existing module (e.g. POST /v1/organizations/me/roles), when the user says "scaffold endpoint", "add endpoint", "new route", or when building out controllers/services/repositories together. Covers schema → repository → DTO → service → controller in one pass.
---

# Nest Endpoint Scaffold

Scaffolds a single REST endpoint end-to-end across the six layers, enforcing the
project's architectural rules. Use this when adding any new route to an existing
NestJS module.

## The 6-step recipe (always in this order)

Each step has a single responsibility. Skipping a layer or merging two layers is a
bug-magnet — controllers grow business logic, services grow HTTP awareness.

1. **Schema** (`schemas/{name}.schema.ts`) — Mongoose model, prefixed collection
2. **Repository** (`repositories/{name}.repository.ts`) — all Mongoose queries
3. **DTO** (`dto/{verb}-{noun}.dto.ts`) — class-validator + `@ApiProperty`
4. **Service** (`{module}/{feature}/{feature}.service.ts`) — pure business logic
5. **Controller** (`{module}/{feature}/{feature}.controller.ts`) — HTTP only
6. **Integration test** — invoke the `nest-integration-test` skill

## Layer responsibilities (the rule)

```
Controller   →   parses HTTP, calls service, returns service result. NO logic.
Service      →   business rules, validation beyond DTO, throws AppError. NO Mongoose.
Repository   →   Mongoose queries only. NO business rules. NO HTTP.
```

If a controller does anything more than `return this.service.x(args)`, it's wrong.
If a service imports `mongoose` or `Model`, it's wrong.
If a repository throws `AppError`, it's probably wrong.

## Step 1 — Schema

```typescript
// src/modules/{module}/schemas/role.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Document } from 'mongoose'

@Schema({ timestamps: true, collection: 'identity_roles' }) // ALWAYS prefixed
export class Role {
  @Prop({ required: true }) name: string
  @Prop({ required: true }) group: string
  @Prop({ type: String, default: null }) organizationId: string | null
  @Prop({ type: [String], default: [] }) permissions: string[]
  @Prop({ default: false }) isSystem: boolean
  @Prop({ type: Date, default: null }) deletedAt: Date | null
}

export type RoleDocument = Role & Document
export const RoleSchema = SchemaFactory.createForClass(Role)
```

**Rules:**
- `collection: '{module-prefix}_{noun-plural}'` is mandatory
- `timestamps: true` is mandatory
- Union types like `Date | null` need explicit `@Prop({ type: Date, default: null })`
- Cross-module IDs are `String`, never `ObjectId`
- Money is integer minor units; the unit goes in the field name (`amountCents`)
- Soft-delete with `deletedAt: Date | null`

## Step 2 — Repository

```typescript
// src/modules/{module}/repositories/role.repository.ts
import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { Role, RoleDocument } from '../schemas/role.schema'

@Injectable()
export class RoleRepository {
  constructor(@InjectModel(Role.name) private readonly model: Model<RoleDocument>) {}

  findById(id: string) {
    return this.model.findById(id).lean()
  }

  listForOrg(organizationId: string) {
    return this.model
      .find({ organizationId, deletedAt: null })
      .sort({ createdAt: -1 })
      .lean()
  }

  async createCustom(input: { ... }) {
    return this.model.create({ ...input, isSystem: false })
  }
}
```

**Rules:**
- One repository per schema. Repositories never call other repositories.
- Always use `.lean()` for reads — typed plain objects, no Mongoose document overhead
- Never query another module's collections. If you need cross-module data, call the
  other module's contract (`MODULE_CONTRACT` token) from the service layer.

## Step 3 — DTO

```typescript
// src/modules/{module}/dto/create-role.dto.ts
import { ApiProperty } from '@nestjs/swagger'
import { IsArray, IsString, Length } from 'class-validator'

export class CreateRoleDto {
  @ApiProperty({ example: 'Procurement Officer', minLength: 2, maxLength: 80 })
  @IsString()
  @Length(2, 80)
  name!: string

  @ApiProperty({ example: ['procurement.rfq.create', 'procurement.rfq.view'] })
  @IsArray()
  @IsString({ each: true })
  permissions!: string[]
}
```

**Rules:**
- Every field gets `@ApiProperty` — non-negotiable, CI fails otherwise
- Use `!` (definite assignment) on required fields — strict mode enforces it
- Boundary validation only (lengths, formats). Business rules belong in the service.
- Response DTOs are separate types (`{Name}SummaryDto`) — never return Mongoose docs

## Step 4 — Service

```typescript
// src/modules/{module}/{feature}/{feature}.service.ts
import { Injectable } from '@nestjs/common'
import { ConflictError, ForbiddenError, NotFoundError } from '@/shared/lib/api-error'
import { RoleRepository } from '../repositories/role.repository'
import type { CreateRoleDto } from '../dto/create-role.dto'
import type { RoleSummaryDto } from '../dto/role-summary.dto'

@Injectable()
export class RolesService {
  constructor(private readonly roles: RoleRepository) {}

  async create(
    actor: { organizationId: string; group: string },
    dto: CreateRoleDto,
  ): Promise<RoleSummaryDto> {
    // 1. Validate business rules (subset, group match, etc.)
    // 2. Mutate via repository
    // 3. Map document → DTO via `toRoleSummary(doc, idOf(doc))`
  }
}
```

**Rules:**
- Throw `AppError` subclasses only — never `new Error()`, never `throw 'string'`
  - `NotFoundError('Role')` → 404
  - `ConflictError('Role still assigned to N users')` → 409
  - `ForbiddenError('Role contains permissions outside your group')` → 403
  - `ValidationError(...)` → 422 (boundary errors; DTO handles most)
- Services orchestrate other services/repositories via DI. No `new RoleRepository()`.
- Cross-module calls go through `@Inject(MODULE_CONTRACT)`, never the concrete class.
- Use the `idOf(doc)` helper for any `_id` extraction (see below).

### The `idOf` helper (copy verbatim into each service file that needs it)

```typescript
function idOf(doc: unknown): string {
  if (typeof doc !== 'object' || doc === null || !('_id' in doc)) {
    throw new Error('document has no _id')
  }
  const id = (doc as { _id: unknown })._id
  if (id === undefined || id === null) throw new Error('document has no _id')
  if (typeof id === 'string') return id
  if (typeof id === 'object' && 'toString' in id && typeof id.toString === 'function') {
    return (id as { toString: () => string }).toString()
  }
  throw new Error('document _id is not stringifiable')
}
```

Mongoose `.lean()` returns objects whose `_id` is `unknown` in the typings; this helper
narrows it. Don't reach for `as string` shortcuts.

## Step 5 — Controller

```typescript
// src/modules/{module}/{feature}/{feature}.controller.ts
import { Body, Controller, Post, UseGuards } from '@nestjs/common'
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger'
import { CurrentUser } from '@/shared/decorators/current-user.decorator'
import { RequirePermissions } from '@/shared/decorators/permissions.decorator'
import { JwtAuthGuard } from '@/shared/guards/jwt-auth.guard'
import { PermissionsGuard } from '@/shared/guards/permissions.guard'
import type { JWTPayload } from '@/shared/types/jwt'
import { CreateRoleDto } from '../dto/create-role.dto'
import { RoleSummaryDto } from '../dto/role-summary.dto'
import { RolesService } from './roles.service'

@ApiTags('organisations')
@ApiBearerAuth()
@Controller('organizations/me/roles')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class RolesController {
  constructor(private readonly roles: RolesService) {}

  @Post()
  @RequirePermissions('org.roles.create')
  @ApiOperation({ summary: 'Create a custom role in the caller organisation' })
  @ApiResponse({ status: 201, type: RoleSummaryDto })
  create(@CurrentUser() user: JWTPayload, @Body() dto: CreateRoleDto) {
    return this.roles.create({ organizationId: user.organizationId, group: user.group }, dto)
  }
}
```

**Rules:**
- Permissions live at the controller (`@RequirePermissions(...)`), never inside services.
  This keeps the auth surface visible in one place.
- Every endpoint needs `@ApiOperation` AND `@ApiResponse` — CI enforces it.
- `@Controller('organizations/...')` — no leading slash, no `v1/` (global prefix handles it).
- Use `@CurrentUser()` to get the JWT payload; don't read `req.user` directly.
- Return the service result. Never `res.json(...)`. The `ResponseTransformInterceptor`
  wraps it in `{ data }`.

## Step 6 — Module wiring

If the feature is brand-new, register its controller/service/repository in the module
file. If extending an existing feature, the wiring usually exists.

```typescript
// src/modules/identity/identity.module.ts
@Module({
  imports: [MongooseModule.forFeature([{ name: Role.name, schema: RoleSchema }, ...])],
  controllers: [..., RolesController],
  providers: [..., RolesService, RoleRepository],
  exports: [IDENTITY_CONTRACT],
})
export class IdentityModule {}
```

## Step 7 — Permission codes

If the endpoint introduces a new permission, register it in
`src/modules/{module}/seeds/permission-registry.ts` AND grant it to the relevant
default roles in `default-role-permissions.ts`. Bump the seed migration if the seeder
uses versioning.

Format: `{module}.{resource}.{action}` — e.g. `org.roles.create`, `payment.escrow.release`.

## Response envelope (what the client sees)

```json
// Success
{ "data": { "id": "...", "name": "...", ... } }

// List with pagination
{ "data": [ ... ], "meta": { "page": 1, "limit": 20, "total": 43, "totalPages": 3 } }

// Error
{ "error": { "code": "CONFLICT", "message": "Role still assigned to 3 users" } }
```

The interceptor wraps successes; the filter formats errors. Don't construct these
shapes manually.

## Status codes (the ones that bite)

| Code | When |
|---|---|
| 200 | Read or update |
| 201 | Create |
| 204 | Delete (no body) |
| 401 | Missing/invalid JWT |
| 402 | OTP required (escrow >$5k) |
| 403 | JWT valid, permission missing |
| 404 | Resource not found OR not in caller's org (don't leak existence) |
| 409 | Conflict (duplicate, wrong state, still referenced) |
| 422 | Validation error |

## Final checks before opening a PR

- [ ] Collection name is prefixed (`identity_*`, `payment_*`, etc.)
- [ ] Schema has `timestamps: true`
- [ ] Repository uses `.lean()` and never queries another module's collections
- [ ] Service throws `AppError` subclasses only
- [ ] Controller has `@ApiOperation` + `@ApiResponse` on every method
- [ ] Permission code follows `{module}.{resource}.{action}`
- [ ] `idOf(doc)` used for every `_id` extraction
- [ ] Integration test exists (invoke `nest-integration-test` skill)
- [ ] `pnpm build && pnpm lint && pnpm test` all green

## Verification incantation (run after every scaffold)

```bash
pnpm build && pnpm lint && pnpm lint:fix && pnpm test
# then smoke test:
pnpm start:dev   # in another terminal: curl the new endpoint
```
