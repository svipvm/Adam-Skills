#!/bin/bash

set -e

SKILL_DIR="${1:-.}"

echo "Building skill: $SKILL_DIR"

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "ERROR: SKILL.md not found"
  exit 1
fi

OUTPUT_DIR="$SKILL_DIR/.output"
mkdir -p "$OUTPUT_DIR"

echo "Parsing SKILL.md..."
cat "$SKILL_DIR/SKILL.md" > "$OUTPUT_DIR/parsed.md"

if [ -d "$SKILL_DIR/includes" ]; then
  echo "Processing includes..."
  for inc in "$SKILL_DIR/includes"/*.md; do
    if [ -f "$inc" ]; then
      echo "  - $(basename $inc)"
    fi
  done
fi

if [ -d "$SKILL_DIR/context" ]; then
  echo "Processing context fragments..."
  for ctx in "$SKILL_DIR/context"/*.md; do
    if [ -f "$ctx" ]; then
      echo "  - $(basename $ctx)"
    fi
  done
fi

echo "Generating INDEX.md..."
{
  echo "# $SKILL_DIR Index"
  echo ""
  echo "## Files"
  echo ""
  find "$SKILL_DIR" -type f -name "*.md" | while read f; do
    echo "- [$f]($f)"
  done
  echo ""
  echo "## Directories"
  echo ""
  find "$SKILL_DIR" -type d | while read d; do
    echo "- $d/"
  done
} > "$SKILL_DIR/INDEX.md"

echo "✓ Build complete"
echo "Output: $OUTPUT_DIR/"
