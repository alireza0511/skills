#!/usr/bin/env bash
set -euo pipefail

# Validate YAML frontmatter in all SKILL.md files.
# Searches skills/<category>/<skill>/<platform>/SKILL.md and skills/<skill>/SKILL.md.
# Required fields: name, description, allowed-tools

EXIT_CODE=0
FILES_CHECKED=0
ERRORS=0

validate_file() {
  local file="$1"
  local has_error=false

  # Check that the file starts with ---
  if ! head -1 "$file" | grep -q '^---$'; then
    echo "ERROR: $file — missing YAML frontmatter opening delimiter (---)"
    has_error=true
    return 1
  fi

  # Extract frontmatter (between first and second ---)
  local frontmatter
  frontmatter=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1{print} found>=2{exit}' "$file")

  if [ -z "$frontmatter" ]; then
    echo "ERROR: $file — empty or malformed YAML frontmatter"
    has_error=true
    return 1
  fi

  # Check closing delimiter
  local delimiter_count
  delimiter_count=$(grep -c '^---$' "$file" || true)
  if [ "$delimiter_count" -lt 2 ]; then
    echo "ERROR: $file — missing YAML frontmatter closing delimiter (---)"
    has_error=true
    return 1
  fi

  # Check required fields
  for field in name description allowed-tools; do
    if ! echo "$frontmatter" | grep -qE "^${field}\s*:"; then
      echo "ERROR: $file — missing required frontmatter field: $field"
      has_error=true
    fi
  done

  if [ "$has_error" = true ]; then
    return 1
  fi

  return 0
}

echo "=== Frontmatter Validation ==="
echo ""

# Find all SKILL.md files under skills/
while IFS= read -r -d '' skill_file; do
  FILES_CHECKED=$((FILES_CHECKED + 1))

  if ! validate_file "$skill_file"; then
    ERRORS=$((ERRORS + 1))
    EXIT_CODE=1
  fi
done < <(find skills -name 'SKILL.md' -print0 2>/dev/null || true)

echo ""
echo "=== Summary ==="
echo "Files checked: $FILES_CHECKED"
echo "Errors:        $ERRORS"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Result:        PASS"
else
  echo "Result:        FAIL"
fi

exit "$EXIT_CODE"
