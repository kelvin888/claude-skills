# claude-skills

Reusable agent skills + global working habits, portable across projects and machines.

## Global habits
- **[AGENTS.md](AGENTS.md)** — tool-agnostic working principles (verify-don't-confirm,
  no-raw-hex, read-the-real-source, keep-the-suite-green). Claude Code can import it from a
  one-line `CLAUDE.md` (`@AGENTS.md`); other agents can read it directly.

## Creative direction
- **[creative-director](creative-director/SKILL.md)** — act as the creative director of an
  award-winning interactive agency: interview → challenge → gated pipeline (brief → concepts
  → storyboard → motion → visual → engineering brief), orchestrating specialist roles. Hands
  off a buildable Engineering Brief (feeds `build-ui-from-design`).

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

## Install (new machine)
Clone the repo, then run the installer for your OS. Both link the skill folders into
`~/.claude/skills/` and import `AGENTS.md` into `~/.claude/CLAUDE.md`. No admin needed;
safe to re-run.

```bash
git clone https://github.com/kelvin888/claude-skills.git ~/.agents/claude-skills
cd ~/.agents/claude-skills
# macOS / Linux (or Windows via WSL / Git Bash):
./install.sh
```

```powershell
# Native Windows (PowerShell):
git clone https://github.com/kelvin888/claude-skills.git $HOME\.agents\claude-skills
cd $HOME\.agents\claude-skills
.\install.ps1
```

Restart Claude Code afterward. Editing flow stays: edit a skill in this repo → commit →
push. (On native Windows, `AGENTS.md` is copied rather than linked, so re-run
`install.ps1` after editing it; skill folders are junctioned and stay live.)

## How it works
Each top-level folder with a `SKILL.md` is one skill. The installer points
`~/.claude/skills/<name>` at this repo, so the repo is the single source of truth. Claude
pulls a skill in when its `description` matches the task, or you invoke it by name.
