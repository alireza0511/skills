#!/usr/bin/env bash
set -euo pipefail

# Check line counts for all SKILL.md files in core/ and stacks/.
# Categories:
#   ideal:              < 150 lines
#   acceptable:         150 - 300 lines
#   needs-justification: 300 - 500 lines
#   too-large:          > 500 lines (causes failure)

EXIT_CODE=0
FILES_CHECKED=0
IDEAL=0
ACCEPTABLE=0
NEEDS_JUSTIFICATION=0
TOO_LARGE=0

echo "=== Line Budget Check ==="
echo ""
printf "%-50s %6s   %-20s\n" "FILE" "LINES" "STATUS"
printf "%-50s %6s   %-20s\n" "----" "-----" "------"

for dir in core stacks; do
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
    line_count=$(wc -l < "$skill_file")

    if [ "$line_count" -gt 500 ]; then
      status="TOO-LARGE"
      TOO_LARGE=$((TOO_LARGE + 1))
      EXIT_CODE=1
    elif [ "$line_count" -gt 300 ]; then
      status="NEEDS-JUSTIFICATION"
      NEEDS_JUSTIFICATION=$((NEEDS_JUSTIFICATION + 1))
    elif [ "$line_count" -ge 150 ]; then
      status="ACCEPTABLE"
      ACCEPTABLE=$((ACCEPTABLE + 1))
    else
      status="IDEAL"
      IDEAL=$((IDEAL + 1))
    fi

    # Color-code output for CI readability
    case "$status" in
      TOO-LARGE)
        printf "%-50s %6d   %-20s\n" "$skill_file" "$line_count" "!! $status"
        echo "::error file=${skill_file}::Line count ${line_count} exceeds hard limit of 500"
        ;;
      NEEDS-JUSTIFICATION)
        printf "%-50s %6d   %-20s\n" "$skill_file" "$line_count" "?  $status"
        echo "::warning file=${skill_file}::Line count ${line_count} exceeds soft limit of 300"
        ;;
      *)
        printf "%-50s %6d   %-20s\n" "$skill_file" "$line_count" "   $status"
        ;;
    esac
  done
done

echo ""
echo "=== Summary ==="
echo "Files checked:        $FILES_CHECKED"
echo "Ideal (<150):         $IDEAL"
echo "Acceptable (150-300): $ACCEPTABLE"
echo "Needs justification:  $NEEDS_JUSTIFICATION"
echo "Too large (>500):     $TOO_LARGE"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Result:               PASS"
else
  echo "Result:               FAIL"
fi

exit "$EXIT_CODE"
