# claude-skills

Reusable agent skills + global working habits, portable across projects and machines.

## Global habits
- **[AGENTS.md](AGENTS.md)** — tool-agnostic working principles (verify-don't-confirm,
  no-raw-hex, read-the-real-source, keep-the-suite-green). Claude Code can import it from a
  one-line `CLAUDE.md` (`@AGENTS.md`); other agents can read it directly.

## Building UI from designs (layered)
- **[build-ui-from-design](build-ui-from-design/SKILL.md)** — the platform-agnostic core
  method: real spec → tokens → real structure → bug-hunt verification → green tests.
- **[build-ui-figma](build-ui-figma/SKILL.md)** — Figma adapter (Figma MCP, asset
  download, arbitrary→canonical Tailwind). Defers method to the core.
- **[build-ui-stitch](build-ui-stitch/SKILL.md)** — Google Stitch adapter (board mapping,
  HTML export, real Tailwind/token reading, canvas-screenshot verification).
- **[tradeaxis-build-ui](tradeaxis-build-ui/SKILL.md)** — project-specific: the full
  TradeAxis Next.js stack (BFF → service → hook → copy → components → view) from Figma.

## Backend (NestJS / TradeAxis)
- **[nest-endpoint-scaffold](nest-endpoint-scaffold/SKILL.md)** — scaffold a REST endpoint
  (schema → repository → DTO → service → controller).
- **[nest-integration-test](nest-integration-test/SKILL.md)** — integration test with
  mongodb-memory-server + supertest.

## Deployment
- **[railway-deploy](railway-deploy/SKILL.md)** — deploy/debug on Railway. **Skeleton** —
  has TODO placeholders for project-specific issues to fill in from real deploys.

## Using these
Each top-level folder with a `SKILL.md` is one skill. To use in Claude Code, make the
folder available under `~/.claude/skills/` (clone here and symlink, or copy). The agent
pulls a skill in when its `description` matches the task, or you invoke it by name.
