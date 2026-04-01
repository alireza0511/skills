#!/usr/bin/env bash
set -euo pipefail

# Check that no code block in SKILL.md exceeds size limits.
# - Warn if a code block > 10 lines (soft limit, SKILL.md only)
# - Fail if a code block > 20 lines (hard limit, SKILL.md only)
# - REFERENCE.md is unlimited and not checked.

EXIT_CODE=0
WARNINGS=0
HARD_FAILURES=0
FILES_CHECKED=0

SOFT_LIMIT=10
HARD_LIMIT=20

check_file() {
  local file="$1"
  local in_block=false
  local block_start=0
  local block_lines=0
  local line_num=0
  local file_has_error=false

  while IFS= read -r line || [ -n "$line" ]; do
    line_num=$((line_num + 1))

    if echo "$line" | grep -qE '^\s*```'; then
      if [ "$in_block" = true ]; then
        # Closing a code block
        if [ "$block_lines" -gt "$HARD_LIMIT" ]; then
          echo "  FAIL: Code block at line $block_start has $block_lines lines (hard limit: $HARD_LIMIT)"
          echo "::error file=${file},line=${block_start}::Code block has ${block_lines} lines, exceeds hard limit of ${HARD_LIMIT}"
          HARD_FAILURES=$((HARD_FAILURES + 1))
          file_has_error=true
        elif [ "$block_lines" -gt "$SOFT_LIMIT" ]; then
          echo "  WARN: Code block at line $block_start has $block_lines lines (soft limit: $SOFT_LIMIT)"
          echo "::warning file=${file},line=${block_start}::Code block has ${block_lines} lines, exceeds soft limit of ${SOFT_LIMIT}"
          WARNINGS=$((WARNINGS + 1))
        fi
        in_block=false
        block_lines=0
      else
        # Opening a code block
        in_block=true
        block_start=$line_num
        block_lines=0
      fi
    elif [ "$in_block" = true ]; then
      block_lines=$((block_lines + 1))
    fi
  done < "$file"

  if [ "$file_has_error" = true ]; then
    return 1
  fi
  return 0
}

echo "=== Code Block Size Check ==="
echo ""

# Find all SKILL.md files under core/ and stacks/
while IFS= read -r -d '' skill_file; do
  FILES_CHECKED=$((FILES_CHECKED + 1))
  echo "Checking: $skill_file"

  if ! check_file "$skill_file"; then
    EXIT_CODE=1
  else
    echo "  OK"
  fi
done < <(find core stacks -name 'SKILL.md' -print0 2>/dev/null || true)

echo ""
echo "=== Summary ==="
echo "Files checked:   $FILES_CHECKED"
echo "Warnings (>$SOFT_LIMIT): $WARNINGS"
echo "Failures (>$HARD_LIMIT): $HARD_FAILURES"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Result:          PASS"
else
  echo "Result:          FAIL"
fi

exit "$EXIT_CODE"
