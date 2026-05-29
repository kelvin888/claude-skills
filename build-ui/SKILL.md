---
name: tradeaxis-build-ui
description: Build a pixel-perfect UI feature for the TradeAxis frontend from one or more Figma URLs. Fetches all frames, audits tokens, downloads assets, builds the full module stack (types → schemas → BFF → service → hook → copy constants → components → view → page), enforces no-hardcoding, and TypeScript-checks the result. Use when the user provides Figma URLs and says "build", "implement", or "create" a UI feature.
---

# TradeAxis — Build UI from Figma

Implements a feature end-to-end from Figma frames following the project's established
patterns. Never skip steps. Never hardcode colors or text. Zero TypeScript errors before
reporting done.

---

## Step 0 — Read CLAUDE.md first

Before touching any file, read `frontend/CLAUDE.md`. All architecture decisions,
BFF patterns, auth adapter usage, and component conventions live there. This skill
layers on top of them — it does not replace them.

---

## Step 1 — Fetch all Figma frames (in parallel)

Call `mcp__figma__get_design_context` for every URL the user provided, all in one
parallel batch. Never fetch sequentially.

Extract from each frame:
- **What it represents**: which screen, step, or component state (empty / filled /
  error / loading / dropdown-open / etc.)
- **Color values** used anywhere in the design
- **Icon/image assets** (Figma CDN URLs in the `const imgXxx = "..."` lines)
- **Typography** scale used (font size, weight, line-height)
- **Spacing** values (padding, gap, border-radius)
- **Interactive states** visible across frames

If the user gives 6 frames and 3 of them are the same screen in different states,
identify the pattern: "Frame A = empty, Frame B = filled, Frame C = dropdown open".
This drives how you build the component.

---

## Step 2 — Audit design tokens

Read `frontend/src/app/globals.css`. The `@theme inline` block contains every CSS
custom property that generates a Tailwind utility.

For each color, shadow, or surface value found in the Figma frames:
1. Check whether an exact or semantically equivalent token already exists.
2. If it exists → use the token class. Never use the raw hex.
3. If it's missing → add it to `globals.css` under the correct semantic group
   (surface, border, brand, status badge, input, etc.) before building any component.

**Existing token reference:**
- Brand greens: `brand-50` → `brand-950`
- Text grays: `gray-400`, `gray-500`, `gray-600`, `gray-700`, `gray-900`, `gray-950`
- Surfaces: `surface-page`, `surface-card`, `surface-muted`, `surface-subtle`
- Border: `border-default`
- Trends: `trend-up`, `trend-down`
- Status badges: `order-qc-bg/text`, `order-pending-bg/text`, `order-transit-bg/text`, `order-active-bg/text`
- Progress bars: `progress-amber`, `progress-orange`
- KPI surfaces: `kpi-volume-bg`, `kpi-orders-bg`, `kpi-transit-bg`, `kpi-savings-bg`
- Activity: `activity-shipped-bg`, `activity-warn-bg`
- FX borders: `fx-ngn`, `fx-kes`, `fx-ghs`
- RFQ inputs: `input-bg`, `step-label`, `upload-border`

For **gradients** and **shadows** that aren't in `@theme inline`, add them as CSS
custom properties under `:root` instead (e.g. `--portal-action-gradient`), then
reference them with `style={{ background: 'var(--portal-action-gradient)' }}`.

---

## Step 3 — Download icon/image assets

For every `const imgXxx = "https://www.figma.com/api/mcp/asset/..."` in the Figma
output that represents an icon or illustration the component needs:

```bash
curl -sL "<figma-cdn-url>" -o public/images/icons/<module>/<name>.svg
file public/images/icons/<module>/<name>.svg   # confirm SVG, rename if PNG
```

Store under `public/images/icons/{module}/`. Reuse existing assets if they match
(e.g. `nav/notification.svg` is already downloaded from a prior session).

Do NOT download sidebar/topbar icons that belong to the shell — those are already
present. Only download icons that are new to the feature being built.

---

## Step 4 — Identify the module and plan the file tree

Determine which module this UI belongs to (dashboard, rfq, supplier, payment,
shipment, qa, trade-ops, notifications, settings, etc.).

Planned file tree (create all applicable files — skip only what genuinely doesn't apply):

```
src/
  app/
    api/{module}/route.ts          ← BFF (GET + POST/PUT/DELETE as needed)
    (portal)/{module}/
      page.tsx                     ← thin server page → renders View
      error.tsx                    ← 'use client', delegates to RouteErrorBoundary
      [id]/page.tsx                ← if detail page exists
      new/page.tsx                 ← if creation form exists

  modules/{module}/
    types/{module}.types.ts        ← TypeScript interfaces + enums
    utils/query-keys.ts            ← TanStack Query key factory
    schemas/                       ← Zod schemas (one per form step)
    services/{module}.service.ts   ← fetch wrappers calling BFF
    hooks/
      use{Feature}.ts              ← useQuery wrappers (staleTime appropriate)
      useCreate{Feature}.ts        ← useMutation wrappers
    constants/copy.ts              ← ALL UI text strings + select option lists
    components/                    ← presentational components
      {Feature}Card.tsx
      {Feature}List.tsx
      ... (one file per component)
    views/
      {Feature}View.tsx            ← smart page-level component
      New{Feature}View.tsx         ← if creation form
```

---

## Step 5 — No-hardcoding: colors

**Rule: zero raw hex values in any component file.**

Mapping process:
1. Look up the hex in `globals.css` → find the token name → use `text-{token}` or
   `bg-{token}`.
2. If not in globals.css → add it first (Step 2), then use the generated class.
3. For gradients → `:root` variable → `style={{ background: 'var(--name)' }}`.
4. For shadows from Figma → use arbitrary Tailwind only if no semantic equivalent
   exists: `shadow-[0px_4px_4px_0px_rgba(0,0,0,0.25)]`.

**Never do this:**
```tsx
<div className="text-[#2c594a]">   ← hardcoded hex — always wrong
<div style={{ color: '#27483e' }}  ← hardcoded hex — always wrong
```

**Do this:**
```tsx
<div className="text-brand-700">   ← token class
<div style={{ background: 'var(--portal-action-gradient)' }}>  ← CSS var
```

---

## Step 6 — No-hardcoding: text

**Rule: zero string literals in JSX that a real user would read.**

All UI copy goes in `constants/copy.ts` as a typed `as const` object, then imported:

```tsx
// constants/copy.ts
export const WIDGET_COPY = {
  title:    'Active Orders',
  subtitle: 'Track your ongoing shipments',
  viewAll:  'View All',
  empty:    'No orders yet',
} as const

// component
import { WIDGET_COPY as COPY } from '../constants/copy'
<p>{COPY.title}</p>
```

Status label maps, category lists, and option arrays also live in `copy.ts` — not
inline in JSX or in the component file.

---

## Step 7 — No-hardcoding: data in BFF mock

**Rule: API payload shapes must not carry raw hex values or inline strings.**

Use semantic variant names in mock data:
```typescript
// BAD — raw hex in API payload
{ bgColor: '#d9eee4', textColor: '#27483e' }

// GOOD — semantic variant, component maps to token
{ variant: 'volume' }  // component has: VARIANT_CLASSES = { volume: { bg: 'bg-kpi-volume-bg', ... } }
```

Status values use the canonical enum strings from `types/{module}.types.ts` which
must match the backend's enum exactly.

---

## Step 8 — Build the BFF (`/app/api/{module}/route.ts`)

Every BFF route handler follows this exact template:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { getAuthContext, requirePermissions, ForbiddenError, UnauthorizedError } from '@/shared/lib/auth/adapter'
import type { SomeSummary } from '@/modules/{module}/types/{module}.types'

const MOCK: SomeSummary = { /* typed mock data — no raw hex, semantic variants only */ }

export async function GET(req: NextRequest) {
  try {
    const auth = await getAuthContext(req)
    requirePermissions(auth, 'procurement.rfq.view')   // appropriate permission

    if (process.env.USE_MOCK === 'true') {
      return NextResponse.json(MOCK)
    }

    const raw = await fetch(`${process.env.API_BASE_URL}/{resource}`, {
      headers: { Authorization: `Bearer ${auth.token}` },
    }).then(r => r.json())

    return NextResponse.json(raw.data)   // always unwrap { data: ... } envelope
  } catch (error) {
    if (error instanceof ForbiddenError)    return NextResponse.json({ error: 'Forbidden' },    { status: 403 })
    if (error instanceof UnauthorizedError) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    return NextResponse.json({ error: 'Failed to fetch' }, { status: 500 })
  }
}
```

- `getAuthContext(req)` — always called, never skip
- `requirePermissions(auth, '...')` — fine-grained; `requireGroup` only for module-level gating
- Mock data lives co-located in the same file under `const MOCK = ...`
- Unwrap `raw.data` envelope on every real backend call

---

## Step 9 — Build service, hook, query keys

**Service** — thin fetch wrappers calling `/api/{module}`, throw `APIError` on non-ok:

```typescript
import { APIError } from '@/shared/lib/api-error'

export const widgetService = {
  getSummary: async (): Promise<WidgetSummary> => {
    const res = await fetch('/api/widget')
    if (!res.ok) throw new APIError(res)
    return res.json()
  },
}
```

**Query keys** — always use the factory pattern:

```typescript
export const widgetKeys = {
  all:     ['widget'] as const,
  summary: () => [...widgetKeys.all, 'summary'] as const,
  list:    (filters?: Filters) => [...widgetKeys.all, 'list', filters] as const,
  detail:  (id: string) => [...widgetKeys.all, 'detail', id] as const,
}
```

**Hook** — wraps useQuery, appropriate `staleTime`:

```typescript
export function useWidgetSummary() {
  return useQuery({
    queryKey: widgetKeys.summary(),
    queryFn:  widgetService.getSummary,
    staleTime: 1000 * 60 * 2,  // 2 min for operational data; 15 min for slow data
  })
}
```

---

## Step 10 — Build components (presentational)

**Input styling from Figma:**
- Empty: `bg-input-bg border border-brand-100 rounded-[16px] px-3.25 py-4.25`
- Filled: `bg-brand-50 border border-brand-100`
- Error: `bg-error-50 border border-error-300`
- Label: `text-body-sm font-medium text-brand-700`
- Placeholder text: `text-neutral-300`
- Helper text: `text-body-sm font-medium text-brand-950`

**Step indicator states (multi-step forms):**
- Done: `size-6.5 rounded-full bg-brand-800` + `<Check className="size-3 text-white" />`
- Current: `size-6.5 rounded-full border-2 border-brand-700 bg-white`
- Upcoming: `size-6.5 rounded-full bg-brand-800` + white number text

**Buttons:**
- Primary (active): `style={{ background: 'var(--portal-action-gradient)' }}` + `text-white font-semibold rounded-[16px] px-3 py-3`
- Secondary/back: `bg-brand-800 text-white font-semibold rounded-[16px] px-3 py-3`
- Disabled: `bg-neutral-200 text-neutral-400 cursor-not-allowed rounded-[16px]`

**Cards:**
- `bg-surface-card border border-black/10 rounded-[14px]`
- Card header: `px-6 py-[23.5px]` with title `text-[18px] font-bold text-gray-950 tracking-[-0.3125px]`
- Card body top divider: `border-t border-brand-100`

**Canonical Tailwind class conversions** (Figma outputs arbitrary values — always convert):
| Figma arbitrary | Canonical |
|---|---|
| `size-[108px]` | `size-27` |
| `h-[22px]` | `h-5.5` |
| `px-[17px]` | `px-4.25` |
| `py-[13px]` | `py-3.25` |
| `gap-[9px]` | `gap-2.25` |
| `pb-[6px]` | `pb-1.5` |
| `pb-[7px]` | `pb-1.75` |
| `px-[9px]` | `px-2.25` |
| `py-[3px]` | `py-0.75` |
| `max-w-[1280px]` | `max-w-7xl` |
| `h-[37px]` | `h-9.25` |
| `size-[26px]` | `size-6.5` |
| `px-[13px]` | `px-3.25` |
| `py-[17px]` | `py-4.25` |

**All states required** per CLAUDE.md §5.2: loading (skeleton), empty, error (with retry), default.

---

## Step 11 — Build view (smart component)

The view orchestrates hooks + components. It owns data fetching and layout.

**For data-display views:**
```tsx
export function WidgetView() {
  const { data, isLoading, isError, error, refetch } = useWidgetSummary()
  if (isLoading) return <WidgetSkeleton />
  if (isError)   return <ErrorState message={error.message} onRetry={refetch} />
  if (!data)     return null
  return <WidgetDisplay data={data} />
}
```

**For multi-step forms:**
- State management with `useReducer` (step navigation + aggregated form data)
- `useDraftPersistence` from `@/shared/hooks/useDraftPersistence` with key `'{module}-new-draft'`
- Restore draft on mount with `useEffect` + `restore()`
- Each step is a separate component with its own RHF form
- Step forms linked to navigation buttons via `form={step-N-form}` + `id="step-N-form"`
- On final submit: call mutation → on success → `clear()` draft → `router.push('/...')`

---

## Step 12 — Build pages and error boundaries

**Page** (server component, thin):
```tsx
// app/(portal)/{module}/page.tsx
import { FeatureView } from '@/modules/{module}/views/FeatureView'
export default function FeaturePage() { return <FeatureView /> }
```

**Error boundary** (required for every data-fetching route):
```tsx
// app/(portal)/{module}/error.tsx
'use client'
import { RouteErrorBoundary } from '@/shared/ui/route-error-boundary'
export default function FeatureError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <RouteErrorBoundary error={error} reset={reset} />
}
```

---

## Step 13 — TypeScript check

After all files are written:

```bash
cd frontend && npx tsc --noEmit
```

**All errors must be resolved before reporting done.** Common issues and fixes:

| Error pattern | Fix |
|---|---|
| `invalid_type_error` in Zod schema | Zod v4 renamed it to `error` |
| `.default([])` causes resolver type mismatch | Remove `.default()`, initialize in `defaultValues` instead |
| `string[] \| undefined` not assignable to `string[]` | Add `?? []` at point of use, or make the type optional |
| `any` in `catch` block | Pattern-match with `instanceof` checks |
| Missing `'use client'` | Add to top of any file that uses hooks, event handlers, or browser APIs |

---

## Reminders

- **Never import from a module's internals** — only from its `index.ts` or same module
- **Never call external APIs from client components** — always go through BFF
- **Never put server state in Zustand** — TanStack Query owns all server state
- **Gradients** go in `:root` as CSS custom properties, referenced via `style={{ background: 'var(...)' }}`
- **All amounts** from backend are in minor units (cents) — divide by 100 and format with currency
- **Mobile-first** — every component must work at 375px before adding responsive breakpoints
- **`'use client'`** is required on any file using hooks, event handlers, `useRef`, `useState`, or browser APIs
- **Figma output has absolute positioning and grid hacks** — always rewrite using flexbox/CSS grid with semantic layout
