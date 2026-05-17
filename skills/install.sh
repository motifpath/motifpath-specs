#!/usr/bin/env bash
# skills/install.sh
#
# Installs all MotifPath Claude skills to ~/.claude/skills/
# Run this after pulling motifpath-specs to install or update skills.
#
# Usage:
#   bash skills/install.sh
#
# To install a specific skill only:
#   bash skills/install.sh git

set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${HOME}/.claude/skills"

# All available skills — add new skills here as they are created
ALL_SKILLS=(
  git
  # adr-writer      ← coming soon
  # plan-writer     ← coming soon
  # bug-refinement  ← coming soon
  # go-standards    ← coming soon
  # vue-standards   ← coming soon
)

# If a specific skill is passed as an argument, install only that one
if [[ $# -gt 0 ]]; then
  SKILLS=("$@")
else
  SKILLS=("${ALL_SKILLS[@]}")
fi

echo ""
echo "MotifPath Skill Installer"
echo "========================="
echo "Installing to: $INSTALL_DIR"
echo ""

mkdir -p "$INSTALL_DIR"

INSTALLED=0
SKIPPED=0
FAILED=0

for skill in "${SKILLS[@]}"; do
  src="$SKILLS_DIR/$skill/SKILL.md"
  dest="$INSTALL_DIR/$skill"

  if [[ ! -f "$src" ]]; then
    echo "⚠️  Skill not found: $skill (skipping)"
    ((SKIPPED++)) || true
    continue
  fi

  # Read version from SKILL.md frontmatter (name: field)
  version=$(grep -m1 "^version:" "$SKILLS_DIR/$skill/SKILL.md" 2>/dev/null \
    | awk '{print $2}' || echo "unknown")

  # Check if already installed at same version
  installed_version="none"
  if [[ -f "$dest/SKILL.md" ]]; then
    installed_version=$(grep -m1 "^version:" "$dest/SKILL.md" 2>/dev/null \
      | awk '{print $2}' || echo "unknown")
  fi

  if [[ "$version" == "$installed_version" && "$version" != "unknown" ]]; then
    echo "✓  $skill — already at v$version (no update needed)"
    ((SKIPPED++)) || true
    continue
  fi

  mkdir -p "$dest"
  cp "$src" "$dest/SKILL.md"

  if [[ "$installed_version" == "none" ]]; then
    echo "✅ Installed: $skill v$version"
  else
    echo "🔄 Updated:   $skill $installed_version → $version"
  fi

  ((INSTALLED++)) || true
done

echo ""
echo "========================="
echo "Done: $INSTALLED installed/updated, $SKIPPED skipped, $FAILED failed"
echo ""

if [[ $INSTALLED -gt 0 ]]; then
  echo "Skills are installed. To use in Claude Code, add to your CLAUDE.md:"
  echo "  /skills $( IFS=' '; echo "${SKILLS[*]}" )"
  echo ""
  echo "Read the changelog for what changed:"
  for skill in "${SKILLS[@]}"; do
    changelog="$SKILLS_DIR/$skill/CHANGELOG.md"
    if [[ -f "$changelog" ]]; then
      echo "  $SKILLS_DIR/$skill/CHANGELOG.md"
    fi
  done
  echo ""
fi
