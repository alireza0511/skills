#!/usr/bin/env bash
#
# update-skills.sh — Pull the latest Copilot skills into a target repository.
#
# Usage:
#   ./update-skills.sh --target /path/to/repo
#   curl -fsSL https://raw.githubusercontent.com/alireza0511/skills/main/scripts/update-skills.sh | bash -s -- --target .
#
set -euo pipefail

SKILLS_REPO="https://github.com/alireza0511/skills.git"
BRANCH="main"
TARGET="."
DEST=".github/skills"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --dest)
      DEST="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--target path] [--branch name] [--dest path]"
      echo ""
      echo "Options:"
      echo "  --target   Target repository path (default: current directory)"
      echo "  --branch   Branch to pull from (default: main)"
      echo "  --dest     Destination within target repo (default: .github/skills)"
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
SKILLS_DEST="$TARGET/$DEST"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "$TEMP_DIR"' EXIT

# ---------------------------------------------------------------------------
# Clone latest skills
# ---------------------------------------------------------------------------
echo "============================================"
echo " Copilot Skills Updater"
echo "============================================"
echo ""
echo "Source:  $SKILLS_REPO ($BRANCH)"
echo "Target:  $TARGET"
echo "Dest:    $DEST"
echo ""

echo "--- Cloning latest skills ---"
git clone --depth 1 --branch "$BRANCH" "$SKILLS_REPO" "$TEMP_DIR" 2>&1 | sed 's/^/  /'

# ---------------------------------------------------------------------------
# Read version and commit info
# ---------------------------------------------------------------------------
VERSION="unknown"
if [[ -f "$TEMP_DIR/manifest.json" ]]; then
  if command -v jq &>/dev/null; then
    VERSION=$(jq -r '.version' "$TEMP_DIR/manifest.json")
  elif command -v python3 &>/dev/null; then
    VERSION=$(python3 -c "import json; print(json.load(open('$TEMP_DIR/manifest.json'))['version'])")
  fi
fi

COMMIT=$(git -C "$TEMP_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
INSTALL_DATE="$(date +%Y-%m-%d)"

echo ""
echo "Version: $VERSION"
echo "Commit:  $COMMIT"
echo ""

# ---------------------------------------------------------------------------
# Copy skills
# ---------------------------------------------------------------------------
echo "--- Installing skills ---"

if [[ -d "$TEMP_DIR/skills" ]]; then
  mkdir -p "$SKILLS_DEST"

  # Remove old skills (clean install)
  rm -rf "${SKILLS_DEST:?}/"*

  cp -R "$TEMP_DIR/skills/"* "$SKILLS_DEST/"
  echo "  Copied skills/ -> $SKILLS_DEST/"
else
  echo "  ERROR: skills/ directory not found in source repo"
  exit 1
fi

# ---------------------------------------------------------------------------
# Generate MANIFEST.md
# ---------------------------------------------------------------------------
echo ""
echo "--- Generating MANIFEST.md ---"

cat > "$SKILLS_DEST/MANIFEST.md" <<EOF
# Installed Copilot Skills

- **Version:** ${VERSION}
- **Commit:** ${COMMIT}
- **Installed on:** ${INSTALL_DATE}
- **Source:** ${SKILLS_REPO}

---
*Updated by update-skills.sh*
EOF

echo "  Created $SKILLS_DEST/MANIFEST.md"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " Update complete"
echo "============================================"
echo "  Version:  $VERSION"
echo "  Commit:   $COMMIT"
echo "  Location: $SKILLS_DEST"
echo ""
echo "Next steps:"
echo "  1. Review changes:  git diff $DEST/"
echo "  2. Commit:          git add $DEST/ && git commit -m 'chore(skills): update copilot skills to $VERSION'"
echo "  3. Push:            git push"
