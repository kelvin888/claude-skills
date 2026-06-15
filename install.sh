#!/usr/bin/env bash
# Install claude-skills into ~/.claude on macOS / Linux (and Windows via WSL or Git Bash).
# Symlinks each skill folder into ~/.claude/skills and wires AGENTS.md into CLAUDE.md.
# No admin/sudo needed. Safe to re-run (idempotent).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DIR"

echo "Linking skills into $SKILLS_DIR"
for dir in "$REPO_DIR"/*/; do
  name="$(basename "$dir")"
  [ -f "${dir}SKILL.md" ] || continue          # only real skill folders
  ln -sfn "$REPO_DIR/$name" "$SKILLS_DIR/$name"
  echo "  linked $name"
done

# Make the shared habits file available and import it from CLAUDE.md
ln -sfn "$REPO_DIR/AGENTS.md" "$CLAUDE_DIR/AGENTS.md"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ] || ! grep -qF "@AGENTS.md" "$CLAUDE_MD"; then
  { echo ""; echo "# Global working habits (managed by claude-skills)"; echo "@AGENTS.md"; } >> "$CLAUDE_MD"
  echo "  imported AGENTS.md into CLAUDE.md"
fi

echo "Done. Restart Claude Code to pick up the skills."
