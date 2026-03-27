#!/usr/bin/env bash
set -euo pipefail

# Validate YAML frontmatter in all SKILL.md files under core/ and stacks/.
# Required fields: name, description, allowed-tools
# The 'name' field must match the parent directory name (kebab-case).

EXIT_CODE=0
FILES_CHECKED=0
ERRORS=0

validate_file() {
  local file="$1"
  local dir_name
  dir_name=$(basename "$(dirname "$file")")
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

  # Verify name matches directory name
  local name_value
  name_value=$(echo "$frontmatter" | grep -E '^name\s*:' | head -1 | sed 's/^name\s*:\s*//' | sed 's/^["'\'']//' | sed 's/["'\'']\s*$//' | xargs)
  if [ -n "$name_value" ] && [ "$name_value" != "$dir_name" ]; then
    echo "ERROR: $file — frontmatter name '$name_value' does not match directory name '$dir_name'"
    has_error=true
  fi

  if [ "$has_error" = true ]; then
    return 1
  fi

  return 0
}

echo "=== Frontmatter Validation ==="
echo ""

for dir in core stacks; do
  if [ ! -d "$dir" ]; then
    continue
  fi

  for skill_dir in "$dir"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_file="${skill_dir}SKILL.md"

    if [ ! -f "$skill_file" ]; then
      echo "WARNING: No SKILL.md found in $skill_dir"
      continue
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))

    if ! validate_file "$skill_file"; then
      ERRORS=$((ERRORS + 1))
      EXIT_CODE=1
    fi
  done
done

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
