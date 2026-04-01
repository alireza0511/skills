#!/usr/bin/env bash
set -euo pipefail

# Verify required structural sections in every SKILL.md file.
# Required:
#   1. YAML frontmatter (--- delimiters)
#   2. At least one heading containing "rule" (e.g., "Hard Rules", "Rules")
#   3. A heading containing "workflow" or "process"
#   4. A heading containing "checklist" OR markdown checkboxes (- [ ])
#
# Also checks:
#   - Every platform SKILL.md has a sibling REFERENCE.md
#   - Multi-platform skill roots (skills/<category>/<name>/) have a CONTRACT.md

EXIT_CODE=0
FILES_CHECKED=0
ERRORS=0

check_file() {
  local file="$1"
  local file_errors=0

  # 1. YAML frontmatter
  local delimiter_count
  delimiter_count=$(grep -c '^---$' "$file" || true)
  if [ "$delimiter_count" -lt 2 ]; then
    echo "  MISSING: YAML frontmatter (--- delimiters)"
    file_errors=$((file_errors + 1))
  fi

  # 2. Heading with "rule"
  if ! grep -qiE '^#{1,6}\s+.*rule' "$file"; then
    echo "  MISSING: heading containing 'rule' (e.g., ## Hard Rules)"
    file_errors=$((file_errors + 1))
  fi

  # 3. Heading with "workflow" or "process"
  if ! grep -qiE '^#{1,6}\s+.*(workflow|process)' "$file"; then
    echo "  MISSING: heading containing 'workflow' or 'process'"
    file_errors=$((file_errors + 1))
  fi

  # 4. Heading with "checklist" or markdown checkboxes
  local has_checklist_heading has_checkboxes
  has_checklist_heading=$(grep -ciE '^#{1,6}\s+.*checklist' "$file" || true)
  has_checkboxes=$(grep -c '^\s*- \[ \]' "$file" || true)

  if [ "$has_checklist_heading" -eq 0 ] && [ "$has_checkboxes" -eq 0 ]; then
    echo "  MISSING: checklist heading or markdown checkboxes (- [ ])"
    file_errors=$((file_errors + 1))
  fi

  # 5. Check for sibling REFERENCE.md
  local dir
  dir=$(dirname "$file")
  if [ ! -f "${dir}/REFERENCE.md" ]; then
    echo "  MISSING: REFERENCE.md in $(dirname "$file")"
    file_errors=$((file_errors + 1))
  fi

  return "$file_errors"
}

echo "=== Structure Check ==="
echo ""

# Find all SKILL.md files under skills/
while IFS= read -r -d '' skill_file; do
  FILES_CHECKED=$((FILES_CHECKED + 1))
  echo "Checking: $skill_file"

  if ! check_file "$skill_file"; then
    ERRORS=$((ERRORS + 1))
    EXIT_CODE=1
    echo "::error file=${skill_file}::Missing required structural sections"
  else
    echo "  OK"
  fi
done < <(find skills -name 'SKILL.md' -print0 2>/dev/null || true)

# Check that multi-platform skills have CONTRACT.md
echo ""
echo "--- CONTRACT.md Check ---"
for skill_root in skills/*/; do
  [ -d "$skill_root" ] || continue

  # Skip skill-development (single-level skill, no platforms)
  # A multi-platform skill has platform subdirs with SKILL.md
  has_platform_dirs=false
  for subdir in "$skill_root"*/; do
    [ -d "$subdir" ] || continue
    if [ -f "${subdir}SKILL.md" ]; then
      has_platform_dirs=true
      break
    fi
  done

  if [ "$has_platform_dirs" = true ]; then
    if [ ! -f "${skill_root}CONTRACT.md" ]; then
      echo "MISSING: ${skill_root}CONTRACT.md (multi-platform skill requires CONTRACT.md)"
      ERRORS=$((ERRORS + 1))
      EXIT_CODE=1
    else
      echo "OK: ${skill_root}CONTRACT.md"
    fi
  fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $FILES_CHECKED"
echo "Files failing: $ERRORS"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Result:        PASS"
else
  echo "Result:        FAIL"
fi

exit "$EXIT_CODE"
