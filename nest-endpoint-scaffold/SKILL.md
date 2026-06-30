---
name: nest-endpoint-scaffold
description: Scaffold a new REST endpoint in a NestJS backend. Use when adding routes to an existing module, when the user says "scaffold endpoint", "add endpoint", "new route", or when building out controllers/services/repositories together. Covers model/schema → repository → DTO → service → controller in one pass. Stack-agnostic — reads CLAUDE.md first, asks about ORM/DB/auth if not found.
---

# Nest Endpoint Scaffold

Scaffolds a single REST endpoint end-to-end across six layers. Use this when adding
any new route to an existing NestJS module.

## Step 0 — Detect the stack before writing anything

Read `CLAUDE.md` / `agents.md` at the repo root (and the relevant module if it has one).
Derive:

| Question | Where to look | If not found |
|---|---|---|
| ORM / DB driver | `package.json` dependencies | Ask: "Mongoose, Prisma, TypeORM, or other?" |
| Database | Config files / driver name | Ask: "MongoDB, PostgreSQL, MySQL, SQLite, or other?" |
| Auth pattern | Existing guards/decorators in the repo | Ask: "How is auth handled — JWT guards, session, API key, or other?" |
| Error handling | Existing exception filters / AppError pattern | Ask: "What error classes/filters does the project use?" |
| Path prefix | `main.ts` global prefix / existing controllers | Infer from existing routes |
| Module structure | `src/modules/` layout | Match what's already there |

Never hardcode project-specific shared utilities (auth decorators, error classes, path
aliases). Read what the project actually uses, then reference those. If you can't find
them, ask before writing.

---

## The 6-layer recipe (always in this order)

Each layer has one responsibility. Merging layers is how controllers grow business logic
and services grow HTTP awareness.

1. **Model / Schema** — ORM model or Mongoose schema, named collection/table
2. **Repository** — all database queries, no business rules
3. **DTO** — input validation + API documentation shape
4. **Service** — pure business logic, throws typed errors
5. **Controller** — HTTP parsing only, delegates to service
6. **Integration test** — invoke the `nest-integration-test` skill

```
Controller   →   parses HTTP, calls service, returns result. NO logic.
Service      →   business rules, throws typed errors. NO ORM queries.
Repository   →   ORM/DB queries only. NO business rules. NO HTTP.
```

---

## Step 1 — Model / Schema

### Mongoose (MongoDB)

```typescript
// src/modules/{module}/schemas/{name}.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Document } from 'mongoose'

@Schema({ timestamps: true, collection: '{prefix}_{noun-plural}' })
export class {Name} {
  @Prop({ required: true }) name: string
  @Prop({ type: Date, default: null }) deletedAt: Date | null
}

export type {Name}Document = {Name} & Document
export const {Name}Schema = SchemaFactory.createForClass({Name})
```

**Rules:** prefix the collection name, always `timestamps: true`, soft-delete with
`deletedAt: Date | null`, cross-module IDs as `String` not `ObjectId`.

### Prisma (PostgreSQL / MySQL / SQLite)

```prisma
// prisma/schema.prisma — add to existing schema
model {Name} {
  id        String   @id @default(cuid())
  name      String
  deletedAt DateTime?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

### TypeORM (PostgreSQL / MySQL)

```typescript
// src/modules/{module}/entities/{name}.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm'

@Entity('{table_name}')
export class {Name} {
  @PrimaryGeneratedColumn('uuid') id: string
  @Column() name: string
  @Column({ nullable: true }) deletedAt: Date | null
  @CreateDateColumn() createdAt: Date
  @UpdateDateColumn() updatedAt: Date
}
```

---

## Step 2 — Repository

The repository isolates all DB access. Services never import the ORM model directly.

```typescript
// src/modules/{module}/repositories/{name}.repository.ts
import { Injectable } from '@nestjs/common'
// Import your ORM model/client here based on the project's pattern

@Injectable()
export class {Name}Repository {
  // Mongoose: constructor(@InjectModel({Name}.name) private model: Model<{Name}Document>) {}
  // Prisma:   constructor(private prisma: PrismaService) {}
  // TypeORM:  constructor(@InjectRepository({Name}) private repo: Repository<{Name}>) {}

  findById(id: string) { /* ... */ }
  list(filters?: unknown) { /* ... */ }
  create(input: unknown) { /* ... */ }
  softDelete(id: string) { /* ... */ }
}
```

**Rules:**
- One repository per model. Repositories never call other repositories.
- For reads, return plain objects (`.lean()` in Mongoose, Prisma returns plain objects by default).
- Never query another module's tables/collections. Cross-module data goes through the other
  module's service or contract token, called from the service layer.

---

## Step 3 — DTO

```typescript
// src/modules/{module}/dto/create-{name}.dto.ts
import { ApiProperty } from '@nestjs/swagger'
import { IsString, Length } from 'class-validator'

export class Create{Name}Dto {
  @ApiProperty({ example: 'My value', minLength: 2, maxLength: 80 })
  @IsString()
  @Length(2, 80)
  name!: string
}
```

**Rules:**
- Every field gets `@ApiProperty` if the project uses Swagger — check `package.json` for
  `@nestjs/swagger`. If present, it's mandatory.
- Use `!` (definite assignment) on required fields in strict mode.
- Boundary validation only (lengths, formats, types). Business rules belong in the service.
- Response DTOs are separate types — never return ORM documents/entities directly.

---

## Step 4 — Service

```typescript
// src/modules/{module}/{feature}/{feature}.service.ts
import { Injectable } from '@nestjs/common'
import { {Name}Repository } from '../repositories/{name}.repository'
import type { Create{Name}Dto } from '../dto/create-{name}.dto'

@Injectable()
export class {Name}Service {
  constructor(private readonly repo: {Name}Repository) {}

  async create(actor: { id: string }, dto: Create{Name}Dto) {
    // 1. Validate business rules
    // 2. Mutate via repository
    // 3. Map document/entity → response DTO
  }
}
```

**Rules:**
- Throw the project's typed error classes (check existing code for the pattern —
  e.g. `NotFoundException`, `ConflictException`, custom `AppError` subclasses, etc.).
  Never `throw new Error('string')` for expected business errors.
- Services orchestrate via DI only. No `new Repository()`.
- Cross-module calls go through the other module's exported service or contract token.

---

## Step 5 — Controller

```typescript
// src/modules/{module}/{feature}/{feature}.controller.ts
import { Body, Controller, Get, Post, UseGuards, Param } from '@nestjs/common'
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger'
// Import the project's auth guard(s), current-user decorator, and permission decorator
// Read the existing controllers to find the exact imports used in this project

@ApiTags('{module}')
@Controller('{resource-path}')   // no leading slash; global prefix is set in main.ts
// @UseGuards(...)               // match the auth pattern the project already uses
export class {Name}Controller {
  constructor(private readonly service: {Name}Service) {}

  @Post()
  @ApiOperation({ summary: 'Create a {name}' })
  @ApiResponse({ status: 201 })
  create(@Body() dto: Create{Name}Dto) {
    return this.service.create(dto)
  }
}
```

**Rules:**
- Copy the guard/decorator pattern from an existing controller in the project — don't invent it.
- Controllers return the service result. Never `res.json(...)`.
- Every endpoint needs `@ApiOperation` + `@ApiResponse` if the project uses Swagger.
- No business logic here. If you're writing an `if` in a controller, it belongs in the service.

---

## Step 6 — Module wiring

Register the new controller, service, and repository in the module:

```typescript
// src/modules/{module}/{module}.module.ts
@Module({
  imports: [
    // Mongoose: MongooseModule.forFeature([{ name: {Name}.name, schema: {Name}Schema }])
    // TypeORM:  TypeOrmModule.forFeature([{Name}])
    // Prisma:   no extra import needed — inject PrismaService directly
  ],
  controllers: [..., {Name}Controller],
  providers:   [..., {Name}Service, {Name}Repository],
})
export class {Module}Module {}
```

---

## Step 7 — Permissions / roles (if the project uses them)

If the endpoint introduces a new permission or role requirement, check whether the project
has a permission registry or seed file and register it there. Ask the author if unsure
where permissions are managed.

---

## Final checks before opening a PR

- [ ] Model/schema has a prefixed collection/table name and timestamps
- [ ] Repository uses the project's lean/plain-object pattern for reads
- [ ] Repository never queries another module's data
- [ ] Service throws typed error classes, not raw `Error`
- [ ] Controller has `@ApiOperation` + `@ApiResponse` on every method (if project uses Swagger)
- [ ] No `new ClassName()` in services or controllers — everything injected via DI
- [ ] Integration test exists (invoke `nest-integration-test` skill)
- [ ] `build`, `lint`, and `test` all green
