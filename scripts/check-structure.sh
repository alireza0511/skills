#!/usr/bin/env bash
set -euo pipefail

# Verify required structural sections in every SKILL.md file.
# Required:
#   1. YAML frontmatter (--- delimiters)
#   2. At least one heading containing "rule" (e.g., "Hard Rules", "Rules")
#   3. A heading containing "workflow" or "process"
#   4. A heading containing "checklist" OR markdown checkboxes (- [ ])

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

  return "$file_errors"
}

echo "=== Structure Check ==="
echo ""

for dir in core stacks agents; do
  if [ ! -d "$dir" ]; then
    continue
  fi

  for skill_dir in "$dir"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_file="${skill_dir}SKILL.md"

    if [ ! -f "$skill_file" ]; then
      continue
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))
    echo "Checking: $skill_file"

    if ! check_file "$skill_file"; then
      ERRORS=$((ERRORS + 1))
      EXIT_CODE=1
      echo "::error file=${skill_file}::Missing required structural sections"
    else
      echo "  OK"
    fi
  done
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
