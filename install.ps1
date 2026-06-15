# Install claude-skills into ~/.claude on native Windows (PowerShell).
# Uses directory JUNCTIONS for skill folders (no admin/Developer Mode needed) and
# copies AGENTS.md in. Safe to re-run. Run from the repo folder:  .\install.ps1
$ErrorActionPreference = "Stop"

$RepoDir   = $PSScriptRoot
$ClaudeDir = Join-Path $HOME ".claude"
$SkillsDir = Join-Path $ClaudeDir "skills"
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

Write-Host "Linking skills into $SkillsDir"
Get-ChildItem -Path $RepoDir -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
  ForEach-Object {
    $link = Join-Path $SkillsDir $_.Name
    if (Test-Path $link) { (Get-Item $link).Delete() }   # remove old link/dir
    New-Item -ItemType Junction -Path $link -Target $_.FullName | Out-Null
    Write-Host "  linked $($_.Name)"
  }

# Copy the shared habits file in (Windows file symlinks need admin; a copy avoids that).
# Re-run this script after editing AGENTS.md to refresh the copy.
Copy-Item -Path (Join-Path $RepoDir "AGENTS.md") -Destination (Join-Path $ClaudeDir "AGENTS.md") -Force

$ClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"
if (-not (Test-Path $ClaudeMd) -or -not (Select-String -Path $ClaudeMd -SimpleMatch "@AGENTS.md" -Quiet)) {
  Add-Content -Path $ClaudeMd -Value "`r`n# Global working habits (managed by claude-skills)`r`n@AGENTS.md"
  Write-Host "  imported AGENTS.md into CLAUDE.md"
}

Write-Host "Done. Restart Claude Code to pick up the skills."
