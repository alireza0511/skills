#!/usr/bin/env bash
#
# install.sh — Install Copilot skills into a target repository.
#
# Usage:
#   ./install.sh --stacks java,react --target /path/to/repo
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_FILE="$SCRIPT_DIR/manifest.json"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
STACKS=""
TARGET="."

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stacks)
      STACKS="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--stacks stack1,stack2,...] [--target path]"
      echo ""
      echo "Options:"
      echo "  --stacks   Comma-separated list of stacks to install (e.g. java,react,flutter)"
      echo "  --target   Target repository path (default: current directory)"
      echo "  -h, --help Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'"
      echo "Run '$0 --help' for usage information."
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
TARGET="$(cd "$TARGET" && pwd)"
SKILLS_DEST="$TARGET/.github/skills"

# Read version from manifest
VERSION="unknown"
if [[ -f "$MANIFEST_FILE" ]]; then
  VERSION=$(python3 -c "import json; print(json.load(open('$MANIFEST_FILE'))['version'])" 2>/dev/null || echo "unknown")
fi

INSTALL_DATE="$(date +%Y-%m-%d)"

echo "============================================"
echo " Bank Copilot Skills Installer v${VERSION}"
echo "============================================"
echo ""
echo "Target:  $TARGET"
echo "Stacks:  ${STACKS:-none}"
echo "Date:    $INSTALL_DATE"
echo ""

# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------
WARNINGS=0
ERRORS=0

validate_skill_file() {
  local skill_file="$1"
  local skill_dir
  skill_dir="$(dirname "$skill_file")"

  # Validate SKILL.md frontmatter has required fields
  local frontmatter
  frontmatter=$(awk '/^---$/{if(++c==2) exit} c' "$skill_file")

  for field in name description allowed-tools; do
    if ! echo "$frontmatter" | grep -q "^${field}:"; then
      echo "  ERROR: $skill_file is missing required frontmatter field: $field"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check REFERENCE.md exists alongside SKILL.md
  if [[ ! -f "$skill_dir/REFERENCE.md" ]]; then
    echo "  ERROR: $skill_dir/ is missing REFERENCE.md"
    ERRORS=$((ERRORS + 1))
  fi

  # Warn if SKILL.md exceeds 300 lines
  local line_count
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [[ "$line_count" -gt 300 ]]; then
    echo "  WARNING: $skill_file is $line_count lines (exceeds 300-line threshold)"
    WARNINGS=$((WARNINGS + 1))
  fi
}

# ---------------------------------------------------------------------------
# Copy core skills
# ---------------------------------------------------------------------------
echo "--- Installing core skills ---"

if [[ -d "$SCRIPT_DIR/core" ]]; then
  mkdir -p "$SKILLS_DEST"
  cp -R "$SCRIPT_DIR/core/"* "$SKILLS_DEST/" 2>/dev/null || true
  echo "  Copied core/* -> $SKILLS_DEST/"

  # Validate each core skill (SKILL.md files may be in platform subdirs)
  while IFS= read -r -d '' skill_file; do
    validate_skill_file "$skill_file"
  done < <(find "$SCRIPT_DIR/core" -name 'SKILL.md' -print0 2>/dev/null || true)
else
  echo "  WARNING: core/ directory not found, skipping."
  WARNINGS=$((WARNINGS + 1))
fi

echo ""

# ---------------------------------------------------------------------------
# Copy selected stacks
# ---------------------------------------------------------------------------
INSTALLED_STACKS=()

if [[ -n "$STACKS" ]]; then
  echo "--- Installing stack skills ---"
  IFS=',' read -ra STACK_LIST <<< "$STACKS"
  for stack in "${STACK_LIST[@]}"; do
    stack="$(echo "$stack" | xargs)"  # trim whitespace
    stack_dir="$SCRIPT_DIR/stacks/$stack"
    if [[ -d "$stack_dir" ]]; then
      mkdir -p "$SKILLS_DEST"
      cp -R "$stack_dir/"* "$SKILLS_DEST/" 2>/dev/null || true
      echo "  Copied stacks/$stack/* -> $SKILLS_DEST/"
      INSTALLED_STACKS+=("$stack")

      # Validate each stack skill
      while IFS= read -r -d '' skill_file; do
        validate_skill_file "$skill_file"
      done < <(find "$stack_dir" -name 'SKILL.md' -print0 2>/dev/null || true)
    else
      echo "  WARNING: stacks/$stack/ not found, skipping."
      WARNINGS=$((WARNINGS + 1))
    fi
  done
  echo ""
fi

# ---------------------------------------------------------------------------
# Generate MANIFEST.md
# ---------------------------------------------------------------------------
echo "--- Generating MANIFEST.md ---"

STACKS_LIST_MD=""
if [[ ${#INSTALLED_STACKS[@]} -gt 0 ]]; then
  for s in "${INSTALLED_STACKS[@]}"; do
    STACKS_LIST_MD="${STACKS_LIST_MD}- ${s}\n"
  done
else
  STACKS_LIST_MD="- (none)\n"
fi

cat > "$SKILLS_DEST/MANIFEST.md" <<EOF
# Installed Copilot Skills

- **Version:** ${VERSION}
- **Installed on:** ${INSTALL_DATE}
- **Source:** bank-copilot-skills

## Installed Stacks

$(echo -e "$STACKS_LIST_MD")
---
*Generated by install.sh*
EOF

echo "  Created $SKILLS_DEST/MANIFEST.md"
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "============================================"
echo " Installation complete"
echo "============================================"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [[ "$ERRORS" -gt 0 ]]; then
  echo "There were validation errors. Please fix them before committing."
  exit 1
fi

if [[ "$WARNINGS" -gt 0 ]]; then
  echo "There were warnings. Review them above."
fi

exit 0
