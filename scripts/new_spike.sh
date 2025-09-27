#!/usr/bin/env bash
# Automated spike generator for labs experiments.
# Usage: bash scripts/new_spike.sh <target_dir> "Title of spike"
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target_dir> \"Title\"" >&2
  exit 1
fi

TARGET_DIR="$1"
TITLE="$2"
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g;s/^-|-$//g')
DATE=$(date +%Y%m%d)
FILENAME="${DATE}-${SLUG}.py"
FILE_PATH="${TARGET_DIR}/${FILENAME}"
mkdir -p "$TARGET_DIR"

if [[ -e "$FILE_PATH" ]]; then
  echo "File already exists: $FILE_PATH" >&2
  exit 1
fi

cat > "$FILE_PATH" <<PY
"""Spike: $TITLE"""
from __future__ import annotations


def main() -> None:
    """Entry point for spike experimentation."""
    # TODO: implement experiment
    print("Spike placeholder - replace with experiment logic.")


if __name__ == "__main__":
    main()
PY

echo "✅ Spike created: $FILE_PATH"
