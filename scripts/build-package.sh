#!/usr/bin/env bash
set -euo pipefail

# Build a distributable tar.gz package of copilot-skills.
# Reads version from manifest.json, packages skills/, agents/,
# install.sh, and manifest.json, then computes a sha256 checksum.

# Read version from manifest.json
if [ ! -f manifest.json ]; then
  echo "ERROR: manifest.json not found in $(pwd)" >&2
  exit 1
fi

VERSION=$(jq -r '.version' manifest.json)

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "ERROR: Could not read version from manifest.json" >&2
  exit 1
fi

ARCHIVE_NAME="copilot-skills-${VERSION}.tar.gz"

echo "Building package version ${VERSION}..." >&2

# Verify required directories and files exist
CONTENTS=()
for item in skills agents install.sh manifest.json; do
  if [ -e "$item" ]; then
    CONTENTS+=("$item")
  else
    echo "WARNING: ${item} not found — skipping" >&2
  fi
done

if [ ${#CONTENTS[@]} -eq 0 ]; then
  echo "ERROR: No content to package" >&2
  exit 1
fi

# Create the archive
tar -czf "$ARCHIVE_NAME" "${CONTENTS[@]}"

echo "Archive created: ${ARCHIVE_NAME}" >&2
echo "Contents:" >&2
tar -tzf "$ARCHIVE_NAME" | head -20 >&2

# Compute sha256 checksum
if command -v sha256sum &>/dev/null; then
  sha256sum "$ARCHIVE_NAME" | tee "${ARCHIVE_NAME}.sha256" >&2
elif command -v shasum &>/dev/null; then
  shasum -a 256 "$ARCHIVE_NAME" | tee "${ARCHIVE_NAME}.sha256" >&2
else
  echo "WARNING: No sha256 tool found — skipping checksum" >&2
fi

echo "Checksum written to: ${ARCHIVE_NAME}.sha256" >&2

# Output the archive path to stdout (for CI to capture)
echo "$ARCHIVE_NAME"
