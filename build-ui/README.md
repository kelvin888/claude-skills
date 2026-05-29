# tradeaxis-build-ui

Build a pixel-perfect UI feature for the TradeAxis frontend from one or more Figma URLs.

---

## When to invoke it

Use this skill any time you want to build a UI feature from a Figma design in the
TradeAxis frontend. It covers the full stack from design tokens through to a working
Next.js page.

**Trigger phrases (any of these will activate the skill):**
- `"Build the [feature] UI from this Figma link: <url>"`
- `"Implement this screen: <figma-url>"`
- `"Create the [module] page from Figma"`
- `"Here are the Figma frames for [feature], implement them"`

---

## What you need to provide

1. **One or more Figma frame URLs** — the skill fetches them all in parallel. The
   more states you share (empty, filled, error, loading), the more complete the output.
2. **The feature/module name** — e.g. "RFQ creation form", "Shipment dashboard widget".
3. *(Optional)* Any known permission key or API endpoint if it differs from conventions.

---

## What the skill produces

A fully wired, TypeScript-clean feature including:
- `globals.css` token additions for any new colors
- Downloaded icon/image assets under `public/images/icons/{module}/`
- Types, Zod schemas, query keys, service, hooks
- Copy constants (`constants/copy.ts`) — no hardcoded strings in JSX
- Presentational components with all required states (loading, empty, error, default)
- Smart view component wiring hooks to components
- Thin server page + `error.tsx` boundary
- BFF route (`/app/api/{module}/route.ts`) with auth + mock support

---

## Quick-start example

```
Build the notifications panel UI from these Figma frames:
- https://www.figma.com/file/abc123/...?node-id=1-1   ← empty state
- https://www.figma.com/file/abc123/...?node-id=1-2   ← with items
- https://www.figma.com/file/abc123/...?node-id=1-3   ← mark-as-read state
```

---

## Prerequisites

- The Figma MCP tool (`mcp__figma__get_design_context`) must be available in your
  agent session, otherwise Step 1 cannot fetch the frames.
- You must be working inside the `frontend/` Next.js workspace so the file paths,
  imports, and `tsconfig` resolve correctly.
- Read `frontend/CLAUDE.md` before making any changes — the skill depends on the
  conventions defined there.
